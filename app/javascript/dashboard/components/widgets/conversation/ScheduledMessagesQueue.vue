<script setup>
import { ref, watch, onMounted } from 'vue';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ScheduledMessageApi from 'dashboard/api/inbox/scheduledMessage';

const props = defineProps({
  conversationId: { type: Number, required: true },
});

const { t } = useI18n();

const scheduledMessages = ref([]);

const fetchScheduledMessages = async () => {
  try {
    const { data } = await ScheduledMessageApi.get(props.conversationId);
    scheduledMessages.value = data.payload;
  } catch (error) {
    scheduledMessages.value = [];
  }
};

const formatScheduledAt = scheduledAt =>
  format(new Date(scheduledAt * 1000), 'MMM d, HH:mm');

const cancelScheduledMessage = async scheduledMessage => {
  try {
    await ScheduledMessageApi.cancel(props.conversationId, scheduledMessage.id);
    scheduledMessages.value = scheduledMessages.value.filter(
      item => item.id !== scheduledMessage.id
    );
    useAlert(t('CONVERSATION.SCHEDULE_MESSAGE.QUEUE.CANCEL_SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION.SCHEDULE_MESSAGE.QUEUE.CANCEL_ERROR'));
  }
};

watch(() => props.conversationId, fetchScheduledMessages);

onMounted(fetchScheduledMessages);

defineExpose({ refresh: fetchScheduledMessages });
</script>

<template>
  <div
    v-if="scheduledMessages.length"
    v-tooltip.top-start="$t('CONVERSATION.SCHEDULE_MESSAGE.QUEUE.TOOLTIP')"
    class="flex gap-2 px-3 pt-2 overflow-x-auto"
  >
    <div
      v-for="item in scheduledMessages"
      :key="item.id"
      class="inline-flex flex-shrink-0 items-center gap-1.5 px-3 py-1 text-xs font-medium rounded-full whitespace-nowrap bg-n-slate-3 text-n-slate-11"
    >
      <span class="flex-shrink-0 i-lucide-clock size-3" />
      <span class="flex-shrink-0">{{
        formatScheduledAt(item.scheduled_at)
      }}</span>
      <span class="max-w-40 truncate text-n-slate-12">{{ item.content }}</span>
      <button
        v-tooltip.top-end="
          $t('CONVERSATION.SCHEDULE_MESSAGE.QUEUE.CANCEL_ITEM')
        "
        type="button"
        class="flex-shrink-0 flex items-center hover:text-n-slate-12 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-n-brand rounded-sm"
        @click="cancelScheduledMessage(item)"
      >
        <span class="i-lucide-x size-3" />
      </button>
    </div>
  </div>
</template>
