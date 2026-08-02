<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import ContactDetailsItem from './ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';

const store = useStore();
const { t } = useI18n();

const currentChat = useMapGetter('getSelectedChat');
const pipelineStages = useMapGetter('pipelineStages/getPipelineStages');

const stageOptions = computed(() => [
  { id: null, name: t('KANBAN.STAGE.NONE') },
  ...pipelineStages.value.map(stage => ({ id: stage.id, name: stage.title })),
]);

const selectedStage = computed(() => {
  const currentStageId = currentChat.value.pipeline_stage_id ?? null;
  const match = stageOptions.value.find(opt => opt.id === currentStageId);
  return match || stageOptions.value[0];
});

const onSelectStage = selectedItem => {
  if (selectedStage.value.id === selectedItem.id) return;

  const conversationId = currentChat.value.id;
  const oldValue = currentChat.value.pipeline_stage_id ?? null;
  const pipelineStageId = selectedItem.id;

  store.dispatch('setCurrentChatPipelineStage', {
    pipelineStageId,
    conversationId,
  });
  store
    .dispatch('assignPipelineStage', { conversationId, pipelineStageId })
    .then(() => {
      useAlert(t('KANBAN.STAGE.CHANGE_SUCCESS', { stage: selectedItem.name }));
    })
    .catch(() => {
      store.dispatch('setCurrentChatPipelineStage', {
        pipelineStageId: oldValue,
        conversationId,
      });
      useAlert(t('KANBAN.STAGE.CHANGE_ERROR'));
    });
};
</script>

<template>
  <div class="px-4 py-2 border-b border-n-weak">
    <ContactDetailsItem compact :title="$t('KANBAN.STAGE.TITLE')" />
    <MultiselectDropdown
      :options="stageOptions"
      :selected-item="selectedStage"
      :multiselector-title="$t('KANBAN.STAGE.TITLE')"
      :multiselector-placeholder="$t('KANBAN.STAGE.TITLE')"
      :no-search-result="$t('KANBAN.STAGE.NONE')"
      :input-placeholder="$t('KANBAN.STAGE.TITLE')"
      @select="onSelectStage"
    />
  </div>
</template>
