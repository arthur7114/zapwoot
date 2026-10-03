# Adds WhatsApp labels (creating any that do not exist yet) to a contact's chat, keeping the labels it already has.
class Waha::AddChatLabelsService
  pattr_initialize [:contact!, :titles!]

  def perform
    phone = contact.phone_number.to_s.delete('^0-9')
    chat_id = client.lid_for_phone(phone) || "#{phone}@c.us"
    current_ids = client.chat_labels(chat_id).pluck('id')
    desired_ids = current_ids | titles.map { |title| whatsapp_label_id(title) }

    client.put_chat_labels(chat_id, desired_ids) unless desired_ids.sort == current_ids.sort
  end

  private

  def whatsapp_label_id(title)
    label = mapping.whatsapp_label_for(title, whatsapp_labels) || client.create_label(title.tr('_', ' ').capitalize)
    label['id']
  end

  def whatsapp_labels
    @whatsapp_labels ||= client.labels
  end

  def mapping
    @mapping ||= Waha::LabelMapping.new(contact.account)
  end

  def client
    @client ||= Waha::Client.new
  end
end
