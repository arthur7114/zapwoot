class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create]
  before_action :check_authorization

  def index
    @campaigns = Current.account.campaigns
  end

  def show; end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params)
  end

  def update
    @campaign.update!(campaign_params)
  end

  def pause
    @campaign.pause!
    render :show
  end

  def resume
    @campaign.resume!
    render :show
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :trigger_only_during_business_hours, :inbox_id, :sender_id,
                                     :scheduled_at,
                                     send_schedule: [:timezone, :daily_limit, { weekdays: [], excluded_dates: [], windows: [[:start, :end]],
                                                                                interval: [:min, :max], batch_pause: [:every, :minutes] }],
                                     audience: [:type, :id], trigger_rules: {}, template_params: {})
  end
end
