<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  stageId: {
    type: [Number, String],
    default: null,
  },
});

const { t } = useI18n();
const pipelineStages = useMapGetter('pipelineStages/getPipelineStages');

const stage = computed(() =>
  pipelineStages.value.find(item => item.id === props.stageId)
);

// Derive a soft background/border from the stage color so the chip reads as a
// funnel stage, visually distinct from label pills.
const badgeStyle = computed(() => {
  const color = stage.value?.color || '#8c8f96';
  return {
    color,
    backgroundColor: `${color}1f`,
    borderColor: `${color}66`,
  };
});
</script>

<template>
  <span
    v-if="stage"
    v-tooltip="t('KANBAN.STAGE.BADGE_TOOLTIP', { stage: stage.title })"
    class="inline-flex items-center gap-1 px-1 max-w-[6rem] text-xs font-medium border rounded truncate rtl:flex-row-reverse"
    :style="badgeStyle"
  >
    <span class="flex-shrink-0 i-lucide-kanban size-3" />
    <span class="truncate">{{ stage.title }}</span>
  </span>
</template>
