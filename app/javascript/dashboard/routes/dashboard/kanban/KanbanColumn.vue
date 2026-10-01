<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import KanbanCard from './KanbanCard.vue';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
  stages: {
    type: Array,
    default: () => [],
  },
  conversations: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['move', 'openConversation']);

const { t } = useI18n();

const localConversations = ref([...props.conversations]);

watch(
  () => props.conversations,
  newConversations => {
    localConversations.value = [...newConversations];
  }
);

const stageColor = computed(() => props.stage.color || 'var(--color-n-brand)');
const tint = percent =>
  `color-mix(in srgb, ${stageColor.value} ${percent}%, transparent)`;

const columnStyle = computed(() => ({
  backgroundColor: tint(12),
  borderTopColor: stageColor.value,
}));
const headerStyle = computed(() => ({ backgroundColor: tint(22) }));

const onChange = event => {
  if (event.added) {
    emit('move', {
      conversationId: event.added.element.id,
      pipelineStageId: props.stage.id,
    });
  }
};
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 w-72 h-full overflow-hidden border-t-4 rounded-lg"
    :style="columnStyle"
  >
    <div
      class="flex items-center gap-2 px-3 py-2.5 border-b border-n-weak"
      :style="headerStyle"
    >
      <span class="min-w-0 text-heading-3 text-n-slate-12 truncate">
        {{ stage.title }}
      </span>
      <span
        class="ltr:ml-auto rtl:mr-auto min-w-6 text-center text-sm font-medium tabular-nums text-n-slate-11 bg-n-slate-3 rounded-full px-2 py-0.5"
      >
        {{ localConversations.length }}
      </span>
    </div>
    <Draggable
      v-model="localConversations"
      :group="{ name: 'kanban-cards' }"
      item-key="id"
      tag="div"
      role="list"
      force-fallback
      class="flex flex-col gap-2 p-2 overflow-y-auto grow min-h-[80px]"
      @change="onChange"
    >
      <template #item="{ element }">
        <KanbanCard
          :conversation="element"
          :stages="stages"
          :current-stage-id="stage.id"
          @open="emit('openConversation', element)"
          @move="emit('move', $event)"
        />
      </template>
      <template v-if="!localConversations.length" #footer>
        <div
          class="flex flex-col items-center justify-center flex-1 gap-1 py-6 text-center"
        >
          <p class="text-xs text-n-slate-10">
            {{ t('KANBAN.EMPTY_COLUMN.TITLE') }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ t('KANBAN.EMPTY_COLUMN.HINT') }}
          </p>
        </div>
      </template>
    </Draggable>
  </div>
</template>
