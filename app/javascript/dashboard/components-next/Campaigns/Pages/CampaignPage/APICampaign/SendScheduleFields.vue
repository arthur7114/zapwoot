<script setup>
import { computed, ref, useId } from 'vue';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import {
  WEEKDAYS,
  buildWindow,
  getTimezones,
} from 'dashboard/components-next/Campaigns/Pages/CampaignPage/APICampaign/sendSchedule.js';

defineProps({
  errors: { type: Object, required: true },
});

const schedule = defineModel({ type: Object, required: true });

const { t } = useI18n();

const ids = {
  timezone: useId(),
  weekdays: useId(),
  windows: useId(),
  excludedDates: useId(),
  interval: useId(),
  batchPause: useId(),
};

const newExcludedDate = ref('');

const timezoneOptions = computed(() =>
  getTimezones().map(zone => ({ value: zone, label: zone }))
);

const isWeekdaySelected = day => schedule.value.weekdays.includes(day);

const toggleWeekday = day => {
  schedule.value.weekdays = isWeekdaySelected(day)
    ? schedule.value.weekdays.filter(item => item !== day)
    : [...schedule.value.weekdays, day];
};

const canRemoveWindow = computed(() => schedule.value.windows.length > 1);

const addWindow = () => {
  const last = schedule.value.windows.at(-1);
  schedule.value.windows.push(
    last ? buildWindow(last.end, '23:59') : buildWindow()
  );
};

const removeWindow = id => {
  schedule.value.windows = schedule.value.windows.filter(
    timeWindow => timeWindow.id !== id
  );
};

const addExcludedDate = () => {
  const date = newExcludedDate.value;
  if (date && !schedule.value.excluded_dates.includes(date)) {
    schedule.value.excluded_dates = [
      ...schedule.value.excluded_dates,
      date,
    ].sort();
  }
  newExcludedDate.value = '';
};

const removeExcludedDate = date => {
  schedule.value.excluded_dates = schedule.value.excluded_dates.filter(
    item => item !== date
  );
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex flex-col gap-1">
      <span
        :id="ids.timezone"
        class="mb-0.5 text-sm font-medium text-n-slate-12"
      >
        {{ t('CAMPAIGN.API.SCHEDULE.TIMEZONE') }}
      </span>
      <Select
        v-model="schedule.timezone"
        :options="timezoneOptions"
        :aria-label="t('CAMPAIGN.API.SCHEDULE.TIMEZONE')"
      />
    </div>

    <div
      role="group"
      :aria-labelledby="ids.weekdays"
      class="flex flex-col gap-2"
    >
      <span :id="ids.weekdays" class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.SCHEDULE.WEEKDAYS') }}
      </span>
      <div class="flex flex-wrap gap-1.5">
        <Button
          v-for="day in WEEKDAYS"
          :key="day.value"
          type="button"
          size="sm"
          :variant="isWeekdaySelected(day.value) ? 'solid' : 'faded'"
          :color="isWeekdaySelected(day.value) ? 'blue' : 'slate'"
          :label="t(`CAMPAIGN.API.SCHEDULE.DAYS.${day.key}`)"
          :aria-label="t(`CAMPAIGN.API.SCHEDULE.DAYS_FULL.${day.key}`)"
          :aria-pressed="isWeekdaySelected(day.value)"
          @click="toggleWeekday(day.value)"
        />
      </div>
      <p v-if="errors.weekdays" class="mb-0 text-xs text-n-ruby-11">
        {{ t('CAMPAIGN.API.SCHEDULE.ERRORS.WEEKDAYS') }}
      </p>
    </div>

    <div
      role="group"
      :aria-labelledby="ids.windows"
      class="flex flex-col gap-2"
    >
      <span :id="ids.windows" class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.SCHEDULE.WINDOWS.LABEL') }}
      </span>
      <p class="mb-0 text-xs text-n-slate-11">
        {{ t('CAMPAIGN.API.SCHEDULE.WINDOWS.HELP') }}
      </p>
      <div
        v-for="timeWindow in schedule.windows"
        :key="timeWindow.id"
        class="flex flex-col gap-1"
      >
        <div class="flex items-end gap-2">
          <Input
            v-model="timeWindow.start"
            type="time"
            :label="t('CAMPAIGN.API.SCHEDULE.WINDOWS.FROM')"
            :message-type="errors.windows[timeWindow.id] ? 'error' : 'info'"
            class="flex-1"
          />
          <Input
            v-model="timeWindow.end"
            type="time"
            :label="t('CAMPAIGN.API.SCHEDULE.WINDOWS.TO')"
            :message-type="errors.windows[timeWindow.id] ? 'error' : 'info'"
            class="flex-1"
          />
          <Button
            type="button"
            variant="faded"
            color="ruby"
            icon="i-lucide-trash"
            :disabled="!canRemoveWindow"
            :aria-label="
              t('CAMPAIGN.API.SCHEDULE.WINDOWS.REMOVE', {
                start: timeWindow.start,
                end: timeWindow.end,
              })
            "
            @click="removeWindow(timeWindow.id)"
          />
        </div>
        <p
          v-if="errors.windows[timeWindow.id]"
          class="mb-0 text-xs text-n-ruby-11"
        >
          {{
            errors.windows[timeWindow.id] === 'OVERLAP'
              ? t('CAMPAIGN.API.SCHEDULE.ERRORS.WINDOW_OVERLAP')
              : t('CAMPAIGN.API.SCHEDULE.ERRORS.WINDOW_INVALID')
          }}
        </p>
      </div>
      <Button
        type="button"
        variant="faded"
        color="slate"
        size="sm"
        class="w-fit"
        icon="i-lucide-plus"
        :label="t('CAMPAIGN.API.SCHEDULE.WINDOWS.ADD')"
        @click="addWindow"
      />
    </div>

    <div
      role="group"
      :aria-labelledby="ids.excludedDates"
      class="flex flex-col gap-2"
    >
      <span :id="ids.excludedDates" class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.SCHEDULE.EXCLUDED_DATES.LABEL') }}
      </span>
      <div class="flex items-end gap-2">
        <Input
          v-model="newExcludedDate"
          type="date"
          :aria-label="t('CAMPAIGN.API.SCHEDULE.EXCLUDED_DATES.INPUT')"
          class="flex-1"
        />
        <Button
          type="button"
          variant="faded"
          color="slate"
          :label="t('CAMPAIGN.API.SCHEDULE.EXCLUDED_DATES.ADD')"
          :disabled="!newExcludedDate"
          @click="addExcludedDate"
        />
      </div>
      <ul
        v-if="schedule.excluded_dates.length"
        class="flex flex-wrap gap-1.5 mb-0 list-none ps-0"
      >
        <li v-for="date in schedule.excluded_dates" :key="date">
          <button
            type="button"
            class="inline-flex items-center gap-1 px-2 py-1 text-xs rounded-md bg-n-alpha-2 text-n-slate-12 hover:bg-n-alpha-3"
            :aria-label="
              t('CAMPAIGN.API.SCHEDULE.EXCLUDED_DATES.REMOVE', { date })
            "
            @click="removeExcludedDate(date)"
          >
            {{ date }}
            <span class="i-lucide-x size-3" aria-hidden="true" />
          </button>
        </li>
      </ul>
    </div>

    <div
      role="group"
      :aria-labelledby="ids.interval"
      class="flex flex-col gap-2"
    >
      <span :id="ids.interval" class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.SCHEDULE.INTERVAL.LABEL') }}
      </span>
      <div class="flex gap-2">
        <Input
          v-model="schedule.interval.min"
          type="number"
          min="0"
          :label="t('CAMPAIGN.API.SCHEDULE.INTERVAL.MIN')"
          :message-type="errors.interval ? 'error' : 'info'"
          class="flex-1"
        />
        <Input
          v-model="schedule.interval.max"
          type="number"
          min="0"
          :label="t('CAMPAIGN.API.SCHEDULE.INTERVAL.MAX')"
          :message-type="errors.interval ? 'error' : 'info'"
          class="flex-1"
        />
      </div>
      <p v-if="errors.interval" class="mb-0 text-xs text-n-ruby-11">
        {{ t('CAMPAIGN.API.SCHEDULE.ERRORS.INTERVAL') }}
      </p>
    </div>

    <div
      role="group"
      :aria-labelledby="ids.batchPause"
      class="flex flex-col gap-2"
    >
      <span :id="ids.batchPause" class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.SCHEDULE.BATCH_PAUSE.LABEL') }}
      </span>
      <p class="mb-0 text-xs text-n-slate-11">
        {{ t('CAMPAIGN.API.SCHEDULE.BATCH_PAUSE.HELP') }}
      </p>
      <div class="flex gap-2">
        <Input
          v-model="schedule.batch_pause.every"
          type="number"
          min="0"
          :label="t('CAMPAIGN.API.SCHEDULE.BATCH_PAUSE.EVERY')"
          :message-type="errors.batchPause ? 'error' : 'info'"
          class="flex-1"
        />
        <Input
          v-model="schedule.batch_pause.minutes"
          type="number"
          min="1"
          :label="t('CAMPAIGN.API.SCHEDULE.BATCH_PAUSE.MINUTES')"
          :message-type="errors.batchPause ? 'error' : 'info'"
          class="flex-1"
        />
      </div>
      <p v-if="errors.batchPause" class="mb-0 text-xs text-n-ruby-11">
        {{ t('CAMPAIGN.API.SCHEDULE.ERRORS.BATCH_PAUSE') }}
      </p>
    </div>

    <Input
      v-model="schedule.daily_limit"
      type="number"
      min="1"
      :label="t('CAMPAIGN.API.SCHEDULE.DAILY_LIMIT.LABEL')"
      :placeholder="t('CAMPAIGN.API.SCHEDULE.DAILY_LIMIT.PLACEHOLDER')"
      :message="
        errors.dailyLimit ? t('CAMPAIGN.API.SCHEDULE.ERRORS.DAILY_LIMIT') : ''
      "
      :message-type="errors.dailyLimit ? 'error' : 'info'"
    />
  </div>
</template>
