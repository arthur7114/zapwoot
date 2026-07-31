<script setup>
import { computed, nextTick, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import KanbanColumn from './KanbanColumn.vue';
import KanbanAddStageForm from './KanbanAddStageForm.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { isAdmin } = useAdmin();

const stages = useMapGetter('pipelineStages/getPipelineStages');
const stageUiFlags = useMapGetter('pipelineStages/getUIFlags');
const conversations = useMapGetter(
  'kanbanConversations/getKanbanConversations'
);
const inboxes = useMapGetter('inboxes/getInboxes');
const agents = useMapGetter('agents/getVerifiedAgents');
const labels = useMapGetter('labels/getLabels');

const selectedInboxId = ref('');
const selectedAssigneeId = ref('');
const selectedLabel = ref('');
const isAddingStage = ref(false);
const addStageFormRef = ref(null);

const firstStageId = computed(() => stages.value[0]?.id);

const columns = computed(() => {
  return stages.value.map(stage => {
    const stageConversations = conversations.value
      .filter(
        conversation =>
          (conversation.pipeline_stage_id ?? firstStageId.value) === stage.id
      )
      .sort((a, b) => b.last_activity_at - a.last_activity_at);
    return { stage, conversations: stageConversations };
  });
});

const applyFilters = () => {
  store.dispatch('kanbanConversations/setFilters', {
    inboxId: selectedInboxId.value ? Number(selectedInboxId.value) : null,
    assigneeId: selectedAssigneeId.value
      ? Number(selectedAssigneeId.value)
      : null,
    label: selectedLabel.value || null,
  });
};

const onMove = async ({ conversationId, pipelineStageId }) => {
  try {
    await store.dispatch('kanbanConversations/moveConversation', {
      conversationId,
      pipelineStageId,
    });
  } catch (error) {
    useAlert(t('KANBAN.MOVE_ERROR'));
  }
};

const onOpenConversation = conversation => {
  router.push(
    accountScopedRoute('inbox_conversation', {
      conversation_id: conversation.id,
    })
  );
};

const confirmAddStage = async title => {
  try {
    await store.dispatch('pipelineStages/create', {
      title,
      position: stages.value.length,
    });
    isAddingStage.value = false;
  } catch (error) {
    useAlert(t('PIPELINE_STAGE_MGMT.ADD.API.ERROR_MESSAGE'));
  }
};

const openAddStageForm = () => {
  isAddingStage.value = true;
  nextTick(() => addStageFormRef.value?.focus());
};

onMounted(() => {
  store.dispatch('pipelineStages/get');
  store.dispatch('kanbanConversations/fetch');
});
</script>

<template>
  <div class="flex flex-col w-full h-full p-4 overflow-hidden">
    <div class="flex flex-wrap items-center gap-2 mb-4">
      <h1 class="text-heading-1 text-n-slate-12">
        {{ t('KANBAN.HEADER') }}
      </h1>
      <select
        v-model="selectedInboxId"
        class="!w-40 !mb-0 ltr:ml-auto rtl:mr-auto"
        :aria-label="t('KANBAN.FILTERS.ALL_INBOXES')"
        @change="applyFilters"
      >
        <option value="">{{ t('KANBAN.FILTERS.ALL_INBOXES') }}</option>
        <option v-for="inbox in inboxes" :key="inbox.id" :value="inbox.id">
          {{ inbox.name }}
        </option>
      </select>
      <select
        v-model="selectedAssigneeId"
        class="!w-40 !mb-0"
        :aria-label="t('KANBAN.FILTERS.ALL_AGENTS')"
        @change="applyFilters"
      >
        <option value="">{{ t('KANBAN.FILTERS.ALL_AGENTS') }}</option>
        <option v-for="agent in agents" :key="agent.id" :value="agent.id">
          {{ agent.name }}
        </option>
      </select>
      <select
        v-model="selectedLabel"
        class="!w-40 !mb-0"
        :aria-label="t('KANBAN.FILTERS.ALL_LABELS')"
        @change="applyFilters"
      >
        <option value="">{{ t('KANBAN.FILTERS.ALL_LABELS') }}</option>
        <option v-for="label in labels" :key="label.id" :value="label.title">
          {{ label.title }}
        </option>
      </select>
    </div>

    <woot-loading-state
      v-if="stageUiFlags.isFetching"
      :message="t('KANBAN.LOADING')"
    />

    <div
      v-else-if="!stages.length"
      class="flex flex-col items-center justify-center grow gap-2"
    >
      <p class="text-sm font-medium text-n-slate-12">
        {{ t('KANBAN.EMPTY_STATE.TITLE') }}
      </p>
      <p class="text-sm text-n-slate-11">
        {{
          isAdmin
            ? t('KANBAN.EMPTY_STATE.DESCRIPTION_ADMIN')
            : t('KANBAN.EMPTY_STATE.DESCRIPTION_AGENT')
        }}
      </p>
      <Button
        v-if="isAdmin && !isAddingStage"
        link
        :label="t('KANBAN.ADD_STAGE.BUTTON')"
        @click="openAddStageForm"
      />
      <KanbanAddStageForm
        v-if="isAdmin && isAddingStage"
        ref="addStageFormRef"
        :is-loading="stageUiFlags.isCreating"
        @confirm="confirmAddStage"
        @cancel="isAddingStage = false"
      />
    </div>

    <div v-else class="flex gap-3 overflow-x-auto grow">
      <KanbanColumn
        v-for="column in columns"
        :key="column.stage.id"
        :stage="column.stage"
        :stages="stages"
        :conversations="column.conversations"
        @move="onMove"
        @open-conversation="onOpenConversation"
      />
      <button
        v-if="isAdmin && !isAddingStage"
        type="button"
        class="flex-shrink-0 w-72 h-10 text-sm text-n-slate-11 border border-dashed border-n-weak rounded-lg hover:border-n-brand hover:text-n-brand"
        @click="openAddStageForm"
      >
        {{ t('KANBAN.ADD_STAGE.BUTTON') }}
      </button>
      <KanbanAddStageForm
        v-if="isAdmin && isAddingStage"
        ref="addStageFormRef"
        layout="column"
        :is-loading="stageUiFlags.isCreating"
        @confirm="confirmAddStage"
        @cancel="isAddingStage = false"
      />
    </div>
  </div>
</template>
