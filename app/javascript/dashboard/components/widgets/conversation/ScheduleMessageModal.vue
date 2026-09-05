<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import DatePicker from 'vue-datepicker-next';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  initialContent: { type: String, default: '' },
});

const emit = defineEmits(['close', 'schedule']);

const { t, locale } = useI18n();

const content = ref(props.initialContent);
const scheduledAt = ref(null);
const activePreset = ref('');
const isCalendarOpen = ref(false);

const atTime = (date, hours, minutes) => {
  const result = new Date(date);
  result.setHours(hours, minutes, 0, 0);
  return result;
};

const addDays = (date, days) => {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
};

const upcomingMonday = from => {
  const result = new Date(from);
  // getDay() is 0 for Sunday; on a Monday this lands on the following week.
  const daysAhead = (8 - result.getDay()) % 7 || 7;
  result.setDate(result.getDate() + daysAhead);
  return result;
};

// Rebuilt on open rather than cached, so a modal left open overnight never offers a
// shortcut that has already passed.
const presets = computed(() => {
  const now = new Date();
  const options = [
    {
      key: 'IN_ONE_HOUR',
      label: t('CONVERSATION.SCHEDULE_MESSAGE.PRESET.IN_ONE_HOUR'),
      value: new Date(now.getTime() + 60 * 60 * 1000),
    },
    {
      key: 'TODAY_EVENING',
      label: t('CONVERSATION.SCHEDULE_MESSAGE.PRESET.TODAY_EVENING'),
      value: atTime(now, 18, 0),
    },
    {
      key: 'TOMORROW_MORNING',
      label: t('CONVERSATION.SCHEDULE_MESSAGE.PRESET.TOMORROW_MORNING'),
      value: atTime(addDays(now, 1), 9, 0),
    },
    {
      key: 'IN_TWO_DAYS',
      label: t('CONVERSATION.SCHEDULE_MESSAGE.PRESET.IN_TWO_DAYS'),
      value: atTime(addDays(now, 2), 9, 0),
    },
    {
      key: 'NEXT_MONDAY',
      label: t('CONVERSATION.SCHEDULE_MESSAGE.PRESET.NEXT_MONDAY'),
      value: atTime(upcomingMonday(now), 9, 0),
    },
  ];

  // "Today at 6pm" is noise after 5pm, and invalid after 6.
  return options.filter(
    option => option.value.getTime() - now.getTime() > 30 * 60 * 1000
  );
});

const dateFormatter = computed(
  () =>
    new Intl.DateTimeFormat(locale.value, {
      weekday: 'short',
      day: '2-digit',
      month: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    })
);

const relativeLabel = computed(() => {
  if (!scheduledAt.value) return '';
  const minutes = Math.round((scheduledAt.value - new Date()) / 60000);
  const rtf = new Intl.RelativeTimeFormat(locale.value, { numeric: 'auto' });
  if (minutes < 60) return rtf.format(minutes, 'minute');
  if (minutes < 60 * 24) return rtf.format(Math.round(minutes / 60), 'hour');
  return rtf.format(Math.round(minutes / (60 * 24)), 'day');
});

const summary = computed(() =>
  scheduledAt.value ? dateFormatter.value.format(scheduledAt.value) : ''
);

// vue-datepicker-next ships English month and weekday names; derive them from the
// active locale so the calendar matches the rest of the dashboard.
const datePickerLang = computed(() => {
  const monthName = new Intl.DateTimeFormat(locale.value, { month: 'long' });
  const weekdayShort = new Intl.DateTimeFormat(locale.value, {
    weekday: 'short',
  });
  const weekdayNarrow = new Intl.DateTimeFormat(locale.value, {
    weekday: 'narrow',
  });
  const monthAt = index => new Date(2021, index, 1);
  const weekdayAt = index => new Date(2021, 7, 1 + index);

  return {
    formatLocale: {
      firstDayOfWeek: 0,
      months: Array.from({ length: 12 }, (_, i) =>
        monthName.format(monthAt(i))
      ),
      monthsShort: Array.from({ length: 12 }, (_, i) =>
        monthName.format(monthAt(i)).slice(0, 3)
      ),
      weekdaysShort: Array.from({ length: 7 }, (_, i) =>
        weekdayShort.format(weekdayAt(i))
      ),
      weekdaysMin: Array.from({ length: 7 }, (_, i) =>
        weekdayNarrow.format(weekdayAt(i))
      ),
    },
    monthBeforeYear: true,
  };
});

const isFormValid = computed(
  () => content.value.trim().length > 0 && !!scheduledAt.value
);

const selectPreset = preset => {
  scheduledAt.value = preset.value;
  activePreset.value = preset.key;
  isCalendarOpen.value = false;
};

const openCalendar = () => {
  isCalendarOpen.value = true;
  activePreset.value = '';
};

const onCustomDate = value => {
  scheduledAt.value = value;
  activePreset.value = '';
};

const disabledDate = date => date < atTime(new Date(), 0, 0);

const disabledTime = date => date < new Date();

const onClose = () => emit('close');

const onSchedule = () => {
  if (!isFormValid.value) return;
  emit('schedule', {
    content: content.value,
    scheduledAt: scheduledAt.value,
  });
};
</script>

<template>
  <div class="flex flex-col">
    <woot-modal-header
      :header-title="$t('CONVERSATION.SCHEDULE_MESSAGE.TITLE')"
    />
    <form
      class="w-full px-5 pt-2 pb-6 modal-content"
      @submit.prevent="onSchedule"
    >
      <TextArea
        v-model="content"
        class="mb-5"
        :label="$t('CONVERSATION.SCHEDULE_MESSAGE.CONTENT_LABEL')"
        auto-height
      />

      <fieldset class="mb-5">
        <legend class="mb-2 text-sm font-medium text-n-slate-12">
          {{ $t('CONVERSATION.SCHEDULE_MESSAGE.WHEN_LABEL') }}
        </legend>

        <div class="flex flex-wrap gap-2">
          <button
            v-for="preset in presets"
            :key="preset.key"
            type="button"
            :aria-pressed="activePreset === preset.key"
            class="h-8 px-3 text-sm transition-colors rounded-lg outline outline-1"
            :class="
              activePreset === preset.key
                ? 'bg-n-brand/10 text-n-blue-11 outline-n-brand'
                : 'text-n-slate-12 outline-n-container hover:bg-n-alpha-2'
            "
            @click="selectPreset(preset)"
          >
            {{ preset.label }}
          </button>

          <button
            v-if="!isCalendarOpen"
            type="button"
            class="h-8 px-3 text-sm underline transition-colors rounded-lg text-n-slate-11 underline-offset-2 hover:text-n-slate-12"
            @click="openCalendar"
          >
            {{ $t('CONVERSATION.SCHEDULE_MESSAGE.PICK_DATE') }}
          </button>
        </div>

        <div
          v-if="isCalendarOpen"
          class="p-2 mt-3 rounded-lg outline outline-1 outline-n-container"
        >
          <DatePicker
            :value="scheduledAt"
            type="datetime"
            inline
            :clearable="false"
            :editable="false"
            :show-second="false"
            :lang="datePickerLang"
            :disabled-date="disabledDate"
            :disabled-time="disabledTime"
            :time-picker-options="{
              start: '07:00',
              step: '00:30',
              end: '21:00',
            }"
            @update:value="onCustomDate"
          />
        </div>
      </fieldset>

      <p
        v-if="scheduledAt"
        class="mb-4 text-sm text-n-slate-12"
        aria-live="polite"
      >
        {{
          $t('CONVERSATION.SCHEDULE_MESSAGE.SUMMARY', {
            when: summary,
            relative: relativeLabel,
          })
        }}
      </p>

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('CONVERSATION.SCHEDULE_MESSAGE.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :disabled="!isFormValid"
          :label="$t('CONVERSATION.SCHEDULE_MESSAGE.CONFIRM')"
        />
      </div>
    </form>
  </div>
</template>
