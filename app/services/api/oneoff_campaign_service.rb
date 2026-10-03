# Drip campaign for API (unofficial WhatsApp) inboxes. One message per run, paced by Campaigns::SendSchedule.
class Api::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign!
    build_recipients
    token = SecureRandom.hex(8)
    campaign.update!(dispatch_token: token)
    enqueue_next(token, schedule.next_allowed_at(Time.current))
  end

  # Sends a single message when the schedule allows it. Returns when to run again, or nil once nothing is left to send.
  def dispatch_next
    now = Time.current
    slot = schedule.next_allowed_at(now)
    return slot if slot > now
    return schedule.next_day_start(now) if daily_limit_reached?(now)

    recipient = campaign.campaign_recipients.queued.order(:id).first
    return complete_campaign if recipient.nil?

    deliver(recipient)
    return now if recipient.skipped?

    schedule.next_allowed_at(now + schedule.delay_after(campaign.campaign_recipients.where.not(status: :queued).count))
  end

  def enqueue_next(token, run_at)
    Campaigns::SendApiMessageJob.set(wait_until: run_at).perform_later(campaign, token)
  end

  private

  delegate :inbox, to: :campaign

  def schedule
    @schedule ||= Campaigns::SendSchedule.new(campaign.send_schedule)
  end

  def validate_campaign!
    raise "Invalid campaign #{campaign.id}" unless inbox.inbox_type == 'API' && campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?
  end

  def build_recipients
    audience_contacts.find_in_batches do |contacts|
      rows = contacts.map do |contact|
        { account_id: campaign.account_id, campaign_id: campaign.id, contact_id: contact.id, inbox_id: inbox.id,
          created_at: Time.current, updated_at: Time.current }
      end
      CampaignRecipient.insert_all(rows, unique_by: [:campaign_id, :contact_id]) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def audience_contacts
    campaign.account.contacts.tagged_with(audience_label_titles, any: true)
  end

  def audience_label_titles
    @audience_label_titles ||= begin
      label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
      campaign.account.labels.where(id: label_ids).pluck(:title)
    end
  end

  # Tags the WhatsApp chat with the campaign's audience labels once the message has had time to reach the phone.
  def label_whatsapp_chat(contact)
    return unless inbox.id.to_s == ENV.fetch('WAHA_INBOX_ID', nil)

    Waha::AddChatLabelsJob.set(wait: 2.minutes).perform_later(contact, audience_label_titles)
  end

  def daily_limit_reached?(now)
    return false unless schedule.daily_limit

    campaign.campaign_recipients.where(sent_at: schedule.day_range(now)).count >= schedule.daily_limit
  end

  def complete_campaign
    campaign.with_lock { campaign.completed! unless campaign.completed? }
    nil
  end

  def deliver(recipient)
    contact = recipient.contact
    return recipient.mark_skipped!('Phone number is missing') if contact.phone_number.blank?

    content = Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)
    recipient.update!(message_content: content)
    message = create_message(contact, content)
    recipient.mark_sent!(message)
    label_whatsapp_chat(contact)
  rescue StandardError => e
    Rails.logger.error("[API Campaign #{campaign.id}] Failed to send to contact #{recipient.contact_id}: #{e.message}")
    recipient.mark_failed!(e.message)
  end

  def create_message(contact, content)
    contact_inbox = ContactInboxBuilder.new(contact: contact, inbox: inbox).perform
    conversation = contact_inbox.conversations.where.not(status: :resolved).last || create_conversation(contact, contact_inbox)
    conversation.messages.create!(account_id: campaign.account_id, inbox_id: inbox.id, message_type: :outgoing,
                                  content: content, sender: campaign.sender)
  end

  def create_conversation(contact, contact_inbox)
    Conversation.create!(account_id: campaign.account_id, inbox_id: inbox.id, contact_id: contact.id,
                         contact_inbox_id: contact_inbox.id, campaign_id: campaign.id)
  end
end
