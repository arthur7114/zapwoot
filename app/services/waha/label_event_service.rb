# Applies a WhatsApp label change (WAHA label.chat.added / label.chat.deleted) to the
# contact's latest conversation in the WhatsApp inbox.
class Waha::LabelEventService
  pattr_initialize [:event!, :payload!]

  def perform
    return if conversation.blank? || label_name.blank? || mapping.system?(label_name)

    stage = mapping.stage_for(label_name)
    if stage
      conversation.update!(pipeline_stage: stage) if added? && conversation.pipeline_stage_id != stage.id
    else
      update_conversation_label
    end
  end

  private

  def added?
    event == 'label.chat.added'
  end

  def update_conversation_label
    title = mapping.conversation_label_title(label_name)
    if added?
      inbox.account.labels.find_or_create_by!(title: title)
      conversation.update_labels(conversation.label_list | [title])
    else
      conversation.update_labels(conversation.label_list - [title])
    end
  end

  def label_name
    @label_name ||= payload.dig('label', 'name') || client.labels.find { |label| label['id'] == payload['labelId'].to_s }&.dig('name')
  end

  def conversation
    @conversation ||= begin
      contacts = inbox.account.contacts.where(phone_number: phone_variants.map { |phone| "+#{phone}" })
      inbox.conversations.where(contact_id: contacts.select(:id)).order(last_activity_at: :desc).first
    end
  end

  # Brazilian mobile numbers show up both with and without the ninth digit.
  def phone_variants
    chat_id = payload['chatId'].to_s
    phone = (chat_id.end_with?('@lid') ? client.phone_for_lid(chat_id) : chat_id).to_s.delete('^0-9')
    return [phone] unless phone.start_with?('55')

    if phone.length == 12
      [phone, phone.dup.insert(4, '9')]
    elsif phone.length == 13 && phone[4] == '9'
      [phone, phone.dup.tap { |number| number.slice!(4) }]
    else
      [phone]
    end
  end

  def mapping
    @mapping ||= Waha::LabelMapping.new(inbox.account)
  end

  def inbox
    @inbox ||= Inbox.find(ENV.fetch('WAHA_INBOX_ID'))
  end

  def client
    @client ||= Waha::Client.new
  end
end
