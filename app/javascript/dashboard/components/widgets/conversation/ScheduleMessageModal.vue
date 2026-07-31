<script>
import DatePicker from 'vue-datepicker-next';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

export default {
  components: {
    DatePicker,
    NextButton,
    TextArea,
  },
  props: {
    initialContent: {
      type: String,
      default: '',
    },
  },
  emits: ['close', 'schedule'],
  data() {
    return {
      content: this.initialContent,
      scheduledAt: null,
      lang: {
        days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
        yearFormat: 'YYYY',
        monthFormat: 'MMMM',
      },
    };
  },
  computed: {
    isFormValid() {
      return this.content.trim().length > 0 && !!this.scheduledAt;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSchedule() {
      if (!this.isFormValid) return;
      this.$emit('schedule', {
        content: this.content,
        scheduledAt: this.scheduledAt,
      });
    },
    disabledDate(date) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      return date < yesterday;
    },
    disabledTime(date) {
      const now = new Date();
      return date < now;
    },
  },
};
</script>

<template>
  <div class="flex flex-col">
    <woot-modal-header
      :header-title="$t('CONVERSATION.SCHEDULE_MESSAGE.TITLE')"
    />
    <form
      class="modal-content w-full pt-2 px-5 pb-6"
      @submit.prevent="onSchedule"
    >
      <TextArea
        v-model="content"
        class="mb-4"
        :label="$t('CONVERSATION.SCHEDULE_MESSAGE.CONTENT_LABEL')"
        auto-height
      />
      <div class="date-picker">
        <DatePicker
          v-model:value="scheduledAt"
          type="datetime"
          confirm
          :append-to-body="false"
          :clearable="false"
          :editable="false"
          :confirm-text="$t('CONVERSATION.SCHEDULE_MESSAGE.DATE_CONFIRM')"
          :placeholder="$t('CONVERSATION.SCHEDULE_MESSAGE.DATE_PLACEHOLDER')"
          :lang="lang"
          :disabled-date="disabledDate"
          :disabled-time="disabledTime"
        />
      </div>
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
