class Campaigns::SendApiMessageJob < ApplicationJob
  queue_as :low

  # The token ties the job chain to one run, so a pause followed by a resume never leaves two chains sending at once.
  def perform(campaign, token)
    return unless campaign.processing? && campaign.dispatch_token == token

    service = Api::OneoffCampaignService.new(campaign: campaign)
    next_run_at = service.dispatch_next
    service.enqueue_next(token, next_run_at) if next_run_at
  end
end
