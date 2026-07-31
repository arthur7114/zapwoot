import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import PipelineStagesAPI from '../../api/pipelineStages';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getPipelineStages(_state) {
    return [..._state.records].sort((a, b) => a.position - b.position);
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async function getPipelineStages({ commit }) {
    commit(types.SET_PIPELINE_STAGE_UI_FLAG, { isFetching: true });
    try {
      const response = await PipelineStagesAPI.get();
      commit(types.SET_PIPELINE_STAGES, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_PIPELINE_STAGE_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createPipelineStage({ commit }, stageObj) {
    commit(types.SET_PIPELINE_STAGE_UI_FLAG, { isCreating: true });
    try {
      const response = await PipelineStagesAPI.create(stageObj);
      commit(types.ADD_PIPELINE_STAGE, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PIPELINE_STAGE_UI_FLAG, { isCreating: false });
    }
  },

  update: async function updatePipelineStage({ commit }, { id, ...updateObj }) {
    commit(types.SET_PIPELINE_STAGE_UI_FLAG, { isUpdating: true });
    try {
      const response = await PipelineStagesAPI.update(id, updateObj);
      commit(types.EDIT_PIPELINE_STAGE, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PIPELINE_STAGE_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deletePipelineStage({ commit }, id) {
    commit(types.SET_PIPELINE_STAGE_UI_FLAG, { isDeleting: true });
    try {
      await PipelineStagesAPI.delete(id);
      commit(types.DELETE_PIPELINE_STAGE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PIPELINE_STAGE_UI_FLAG, { isDeleting: false });
    }
  },

  reorder: async function reorderPipelineStages({ commit }, pipelineStageIds) {
    const response = await PipelineStagesAPI.reorder(pipelineStageIds);
    commit(types.SET_PIPELINE_STAGES, response.data.payload);
  },
};

export const mutations = {
  [types.SET_PIPELINE_STAGE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_PIPELINE_STAGES]: MutationHelpers.set,
  [types.ADD_PIPELINE_STAGE]: MutationHelpers.create,
  [types.EDIT_PIPELINE_STAGE]: MutationHelpers.update,
  [types.DELETE_PIPELINE_STAGE]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
