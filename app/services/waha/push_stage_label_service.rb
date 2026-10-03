# Mirrors a conversation's pipeline stage onto the WhatsApp chat: keeps the chat's
# non-stage labels and replaces any stage label with the one for the current stage.
class Waha::PushStageLabelService
  pattr_initialize [:conversation!]

  def perform
    return if phone.blank?

    current_ids = client.chat_labels(chat_id).pluck('id')
    desired_ids = current_ids.reject { |id| stage_label_ids.include?(id) }
    desired_ids << label_id_for(conversation.pipeline_stage) if conversation.pipeline_stage
    desired_ids.compact!

    client.put_chat_labels(chat_id, desired_ids) unless desired_ids.sort == current_ids.sort
  end

  private

  def phone
    @phone ||= conversation.contact.phone_number.to_s.delete('^0-9')
  end

  def chat_id
    @chat_id ||= client.lid_for_phone(phone) || "#{phone}@c.us"
  end

  def stage_label_ids
    @stage_label_ids ||= whatsapp_labels.select { |label| mapping.stage_for(label['name']) }.pluck('id')
  end

  def label_id_for(stage)
    whatsapp_labels.find { |label| mapping.stage_for(label['name']) == stage }&.dig('id')
  end

  def whatsapp_labels
    @whatsapp_labels ||= client.labels
  end

  def mapping
    @mapping ||= Waha::LabelMapping.new(conversation.account)
  end

  def client
    @client ||= Waha::Client.new
  end
end
