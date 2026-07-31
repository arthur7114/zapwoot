class Api::V1::Accounts::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :fetch_pipeline_stage, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @pipeline_stages = policy_scope(Current.account.pipeline_stages)
  end

  def show; end

  def create
    @pipeline_stage = Current.account.pipeline_stages.create!(permitted_params)
  end

  def update
    @pipeline_stage.update!(permitted_params)
  end

  def destroy
    @pipeline_stage.destroy!
    head :ok
  end

  def reorder
    stages_by_id = Current.account.pipeline_stages.where(id: params[:pipeline_stage_ids]).index_by(&:id)
    PipelineStage.transaction do
      params[:pipeline_stage_ids].each_with_index do |id, index|
        stages_by_id[id.to_i]&.update!(position: index)
      end
    end
    @pipeline_stages = policy_scope(Current.account.pipeline_stages)
    render :index
  end

  private

  def fetch_pipeline_stage
    @pipeline_stage = Current.account.pipeline_stages.find(params[:id])
  end

  def permitted_params
    params.require(:pipeline_stage).permit(:title, :color, :position)
  end
end
