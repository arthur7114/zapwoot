import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ConversationApi from '../../api/inbox/conversation';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
  },
  filters: {
    inboxId: null,
    assigneeId: null,
    label: null,
  },
};

export const getters = {
  getKanbanConversations(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getKanbanFilters(_state) {
    return _state.filters;
  },
};

const buildFilterPayload = filters => {
  const payload = [
    {
      attribute_key: 'status',
      filter_operator: 'not_equal_to',
      values: ['resolved'],
      query_operator: 'and',
    },
  ];
  if (filters.inboxId) {
    payload.push({
      attribute_key: 'inbox_id',
      filter_operator: 'equal_to',
      values: [filters.inboxId],
      query_operator: 'and',
    });
  }
  if (filters.assigneeId) {
    payload.push({
      attribute_key: 'assignee_id',
      filter_operator: 'equal_to',
      values: [filters.assigneeId],
      query_operator: 'and',
    });
  }
  if (filters.label) {
    payload.push({
      attribute_key: 'labels',
      filter_operator: 'equal_to',
      values: [filters.label],
      query_operator: 'and',
    });
  }
  // The API rejects a trailing query_operator on the last condition.
  payload[payload.length - 1].query_operator = undefined;
  return payload;
};

const conversationMatchesFilters = (conversation, filters) => {
  if (conversation.status === 'resolved') return false;
  if (filters.inboxId && conversation.inbox_id !== filters.inboxId) {
    return false;
  }
  if (
    filters.assigneeId &&
    conversation.meta?.assignee?.id !== filters.assigneeId
  ) {
    return false;
  }
  if (filters.label && !(conversation.labels || []).includes(filters.label)) {
    return false;
  }
  return true;
};

export const actions = {
  fetch: async function fetchKanbanConversations({ commit, state: _state }) {
    commit(types.SET_KANBAN_CONVERSATION_UI_FLAG, { isFetching: true });
    try {
      const payload = buildFilterPayload(_state.filters);
      const response = await ConversationApi.filter({
        queryData: { payload },
        page: 1,
      });
      commit(types.SET_KANBAN_CONVERSATIONS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_KANBAN_CONVERSATION_UI_FLAG, { isFetching: false });
    }
  },

  setFilters: async function setKanbanFilters({ commit, dispatch }, filters) {
    commit(types.SET_KANBAN_FILTERS, filters);
    await dispatch('fetch');
  },

  moveConversation: async function moveKanbanConversation(
    { commit, state: _state },
    { conversationId, pipelineStageId }
  ) {
    const existing = _state.records.find(
      record => record.id === conversationId
    );
    const previousStageId = existing?.pipeline_stage_id ?? null;
    // Move optimistically so the board reflects the drop (or menu action)
    // instantly, then reconcile with the server response.
    if (existing) {
      commit(types.UPDATE_KANBAN_CONVERSATION, {
        ...existing,
        pipeline_stage_id: pipelineStageId,
      });
    }
    try {
      const response = await ConversationApi.update(conversationId, {
        pipeline_stage_id: pipelineStageId,
      });
      commit(types.UPDATE_KANBAN_CONVERSATION, response.data);
    } catch (error) {
      if (existing) {
        commit(types.UPDATE_KANBAN_CONVERSATION, {
          ...existing,
          pipeline_stage_id: previousStageId,
        });
      }
      throw error;
    }
  },

  applyRealtimeConversation: function applyRealtimeKanbanConversation(
    { commit, state: _state },
    conversation
  ) {
    if (conversationMatchesFilters(conversation, _state.filters)) {
      commit(types.UPDATE_KANBAN_CONVERSATION, conversation);
    } else {
      commit(types.REMOVE_KANBAN_CONVERSATION, conversation.id);
    }
  },
};

export const mutations = {
  [types.SET_KANBAN_CONVERSATION_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_KANBAN_FILTERS](_state, filters) {
    _state.filters = {
      ..._state.filters,
      ...filters,
    };
  },

  [types.SET_KANBAN_CONVERSATIONS]: MutationHelpers.set,
  [types.UPDATE_KANBAN_CONVERSATION]: MutationHelpers.setSingleRecord,
  [types.REMOVE_KANBAN_CONVERSATION]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
