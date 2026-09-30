<script setup>
import { reactive, computed, ref, useId } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import SendScheduleFields from 'dashboard/components-next/Campaigns/Pages/CampaignPage/APICampaign/SendScheduleFields.vue';
import {
  WEEKDAYS,
  buildDefaultSchedule,
  serializeSchedule,
  validateSchedule,
} from 'dashboard/components-next/Campaigns/Pages/CampaignPage/APICampaign/sendSchedule.js';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const props = defineProps({
  // Resolves to true once the campaign is saved; the form keeps its state when it does not.
  submitHandler: { type: Function, required: true },
});

const emit = defineEmits(['cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getAPIInboxes'),
};

const initialState = {
  title: '',
  message: '',
  inboxId: null,
  scheduledAt: null,
  selectedAudience: [],
  sendSchedule: buildDefaultSchedule(),
  riskAcknowledged: false,
};

const state = reactive({ ...initialState });
const riskCheckboxId = useId();
const submitError = ref('');

const rules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1) },
  inboxId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

const currentDateTime = computed(() => {
  // Added to disable the scheduled at field from being set to the current time
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({
    value: item[valueKey],
    label: item[labelKey],
  })) ?? [];

const audienceList = computed(() =>
  mapToOptions(formState.labels.value, 'id', 'title')
);

const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.API.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  message: getErrorMessage('message', 'MESSAGE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  scheduledAt: getErrorMessage('scheduledAt', 'SCHEDULED_AT'),
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
}));

const scheduleErrors = computed(() => validateSchedule(state.sendSchedule));

const isSubmitDisabled = computed(
  () =>
    v$.value.$invalid ||
    scheduleErrors.value.hasErrors ||
    !state.riskAcknowledged
);

const scheduleSummary = computed(() => {
  const schedule = state.sendSchedule;
  const days = WEEKDAYS.filter(day => schedule.weekdays.includes(day.value))
    .map(day => t(`CAMPAIGN.API.SCHEDULE.DAYS.${day.key}`))
    .join(', ');
  const windows = schedule.windows
    .map(({ start, end }) => `${start}–${end}`)
    .join(', ');
  const lines = [
    t('CAMPAIGN.API.SUMMARY.WHEN', {
      days,
      windows,
      timezone: schedule.timezone,
    }),
    t('CAMPAIGN.API.SUMMARY.PACE', {
      min: schedule.interval.min,
      max: schedule.interval.max,
    }),
  ];
  if (Number(schedule.batch_pause.every) > 0) {
    lines.push(
      t('CAMPAIGN.API.SUMMARY.BATCH_PAUSE', {
        every: schedule.batch_pause.every,
        minutes: schedule.batch_pause.minutes,
      })
    );
  }
  lines.push(
    schedule.daily_limit
      ? t('CAMPAIGN.API.SUMMARY.DAILY_LIMIT', { limit: schedule.daily_limit })
      : t('CAMPAIGN.API.SUMMARY.NO_DAILY_LIMIT')
  );
  if (schedule.excluded_dates.length) {
    lines.push(
      t('CAMPAIGN.API.SUMMARY.EXCLUDED', {
        count: schedule.excluded_dates.length,
      })
    );
  }
  return lines;
});

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const handleCancel = () => emit('cancel');

const prepareCampaignDetails = () => ({
  title: state.title,
  message: state.message,
  inbox_id: state.inboxId,
  scheduled_at: formatToUTCString(state.scheduledAt),
  send_schedule: serializeSchedule(state.sendSchedule),
  audience: state.selectedAudience?.map(id => ({
    id,
    type: 'Label',
  })),
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  if (scheduleErrors.value.hasErrors || !state.riskAcknowledged) return;

  submitError.value = '';
  const errorMessage = await props.submitHandler(prepareCampaignDetails());
  if (errorMessage) submitError.value = errorMessage;
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.title"
      :label="t('CAMPAIGN.API.CREATE.FORM.TITLE.LABEL')"
      :placeholder="t('CAMPAIGN.API.CREATE.FORM.TITLE.PLACEHOLDER')"
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <TextArea
      v-model="state.message"
      :label="t('CAMPAIGN.API.CREATE.FORM.MESSAGE.LABEL')"
      :placeholder="t('CAMPAIGN.API.CREATE.FORM.MESSAGE.PLACEHOLDER')"
      show-character-count
      :message="formErrors.message"
      :message-type="formErrors.message ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.CREATE.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('CAMPAIGN.API.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label for="audience" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.CREATE.FORM.AUDIENCE.LABEL') }}
      </label>
      <TagMultiSelectComboBox
        v-model="state.selectedAudience"
        :options="audienceList"
        :label="t('CAMPAIGN.API.CREATE.FORM.AUDIENCE.LABEL')"
        :placeholder="t('CAMPAIGN.API.CREATE.FORM.AUDIENCE.PLACEHOLDER')"
        :has-error="!!formErrors.audience"
        :message="formErrors.audience"
        class="[&>div>button]:bg-n-alpha-black2"
      />
    </div>

    <Input
      v-model="state.scheduledAt"
      :label="t('CAMPAIGN.API.CREATE.FORM.SCHEDULED_AT.LABEL')"
      type="datetime-local"
      :min="currentDateTime"
      :placeholder="t('CAMPAIGN.API.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')"
      :message="formErrors.scheduledAt"
      :message-type="formErrors.scheduledAt ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-3 pt-2 border-t border-n-weak">
      <h4 class="mb-0 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.SCHEDULE.TITLE') }}
      </h4>
      <SendScheduleFields
        v-model="state.sendSchedule"
        :errors="scheduleErrors"
      />
    </div>

    <section
      class="flex flex-col gap-1 p-3 rounded-lg bg-n-alpha-2"
      :aria-label="t('CAMPAIGN.API.SUMMARY.TITLE')"
    >
      <h4 class="mb-1 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.SUMMARY.TITLE') }}
      </h4>
      <p
        v-for="line in scheduleSummary"
        :key="line"
        class="mb-0 text-xs text-n-slate-11"
      >
        {{ line }}
      </p>
    </section>

    <div
      class="flex flex-col gap-2 p-3 border rounded-lg border-n-amber-6 bg-n-amber-2"
      role="note"
    >
      <p class="mb-0 text-xs text-n-amber-11">
        {{ t('CAMPAIGN.API.RISK.NOTICE') }}
      </p>
      <label
        :for="riskCheckboxId"
        class="flex items-start gap-2 mb-0 text-xs font-medium text-n-slate-12"
      >
        <input
          :id="riskCheckboxId"
          v-model="state.riskAcknowledged"
          type="checkbox"
          class="mt-0.5"
        />
        {{ t('CAMPAIGN.API.RISK.ACKNOWLEDGE') }}
      </label>
    </div>

    <p v-if="submitError" role="alert" class="mb-0 text-sm text-n-ruby-11">
      {{ submitError }}
    </p>

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('CAMPAIGN.API.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        :label="t('CAMPAIGN.API.CREATE.FORM.BUTTONS.CREATE')"
        class="w-full"
        type="submit"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
