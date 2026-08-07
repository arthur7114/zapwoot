<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import ContactDetailsItem from './ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const { t } = useI18n();
const { agentsList } = useAgentsList(true, { includeAgentBots: true });

const currentChat = useMapGetter('getSelectedChat');
const currentUser = useMapGetter('getCurrentUser');

const assignedAgent = computed({
  get() {
    const assignee = currentChat.value.meta?.assignee;
    return (
      assignee && {
        ...assignee,
        assignee_type: currentChat.value.meta.assignee_type || 'User',
      }
    );
  },
  set(agent) {
    const agentId = agent ? agent.id : null;
    const assigneeType = agent ? agent.assignee_type || 'User' : null;
    store.dispatch('setCurrentChatAssignee', {
      conversationId: currentChat.value.id,
      assignee: agent,
      assigneeType,
    });
    store
      .dispatch('assignAgent', {
        conversationId: currentChat.value.id,
        agentId,
        assigneeType,
      })
      .then(() => {
        useAlert(t('CONVERSATION.CHANGE_AGENT'));
      });
  },
});

const showSelfAssign = computed(() => {
  if (!assignedAgent.value) return true;
  return (
    assignedAgent.value.id !== currentUser.value.id ||
    (assignedAgent.value.assignee_type || 'User') !== 'User'
  );
});

const onSelfAssign = () => {
  const {
    account_id,
    availability_status,
    available_name,
    email,
    id,
    name,
    role,
    avatar_url,
  } = currentUser.value;
  assignedAgent.value = {
    account_id,
    availability_status,
    available_name,
    email,
    id,
    name,
    role,
    thumbnail: avatar_url,
  };
};

const onClickAssignAgent = selectedItem => {
  if (
    assignedAgent.value?.id === selectedItem.id &&
    (assignedAgent.value?.assignee_type || 'User') ===
      (selectedItem.assignee_type || 'User')
  ) {
    assignedAgent.value = null;
  } else {
    assignedAgent.value = selectedItem;
  }
};
</script>

<template>
  <div class="px-4 py-2 border-b border-n-weak">
    <ContactDetailsItem
      compact
      :title="$t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')"
    >
      <template #button>
        <NextButton
          v-if="showSelfAssign"
          link
          xs
          icon="i-lucide-arrow-right"
          class="!gap-1"
          :label="$t('CONVERSATION_SIDEBAR.SELF_ASSIGN')"
          @click="onSelfAssign"
        />
      </template>
    </ContactDetailsItem>
    <MultiselectDropdown
      :options="agentsList"
      :selected-item="assignedAgent"
      :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
      :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
      :no-search-result="
        $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
      "
      :input-placeholder="
        $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
      "
      @select="onClickAssignAgent"
    />
  </div>
</template>
