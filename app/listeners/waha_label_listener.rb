class WahaLabelListener < BaseListener
  def conversation_updated(event)
    conversation = event.data[:conversation]
    return unless event.data[:changed_attributes]&.key?('pipeline_stage_id')
    return unless conversation.inbox_id.to_s == ENV.fetch('WAHA_INBOX_ID', nil)

    Waha::PushStageLabelJob.perform_later(conversation)
  end
end
