<script setup>
import { computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useTrack } from 'dashboard/composables';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

defineProps({
  isPrivate: { type: Boolean, default: false },
});

const MAX_VISIBLE_QUICK_REPLIES = 8;

const store = useStore();
const cannedResponses = useMapGetter('getCannedResponses');

const quickReplies = computed(() =>
  cannedResponses.value.slice(0, MAX_VISIBLE_QUICK_REPLIES)
);

onMounted(() => {
  if (!cannedResponses.value.length) {
    store.dispatch('getCannedResponse', { searchKey: '' });
  }
});

const insertQuickReply = content => {
  emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, content);
  useTrack(CONVERSATION_EVENTS.INSERTED_A_CANNED_RESPONSE);
};
</script>

<template>
  <div
    v-if="!isPrivate && quickReplies.length"
    class="flex gap-2 px-3 pt-2 overflow-x-auto"
  >
    <button
      v-for="item in quickReplies"
      :key="item.id"
      type="button"
      class="inline-flex flex-shrink-0 items-center gap-1 px-3 py-1 text-xs font-medium rounded-full whitespace-nowrap bg-n-teal-3 text-n-teal-11 hover:bg-n-teal-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-n-brand"
      @click="insertQuickReply(item.content)"
    >
      <span class="flex-shrink-0 i-lucide-zap size-3" />
      {{ item.short_code }}
    </button>
  </div>
</template>
