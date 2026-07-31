/* global axios */
import ApiClient from './ApiClient';

class PipelineStagesAPI extends ApiClient {
  constructor() {
    super('pipeline_stages', { accountScoped: true });
  }

  reorder(pipelineStageIds) {
    return axios.put(`${this.url}/reorder`, {
      pipeline_stage_ids: pipelineStageIds,
    });
  }
}

export default new PipelineStagesAPI();
