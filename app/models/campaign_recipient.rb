# == Schema Information
#
# Table name: campaign_recipients
#
#  id              :bigint           not null, primary key
#  error_message   :text
#  failed_at       :datetime
#  message_content :text
#  sent_at         :datetime
#  status          :integer          default("queued"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  campaign_id     :bigint           not null
#  contact_id      :bigint           not null
#  inbox_id        :bigint           not null
#  message_id      :bigint
#
# Indexes
#
#  index_campaign_recipients_on_campaign_id_and_contact_id  (campaign_id,contact_id) UNIQUE
#  index_campaign_recipients_on_campaign_id_and_sent_at     (campaign_id,sent_at)
#  index_campaign_recipients_on_campaign_id_and_status      (campaign_id,status)
#  index_campaign_recipients_on_contact_id                  (contact_id)
#
# One row per contact in a drip campaign: the queue the sender works through and the record of what happened to each contact.
class CampaignRecipient < ApplicationRecord
  belongs_to :account
  belongs_to :campaign
  belongs_to :contact
  belongs_to :inbox
  belongs_to :message, optional: true

  enum status: { queued: 0, skipped: 1, sent: 2, failed: 3 }

  validates :contact_id, uniqueness: { scope: :campaign_id }

  def mark_sent!(message)
    update!(status: :sent, message: message, sent_at: Time.current, error_message: nil)
  end

  def mark_skipped!(reason)
    update!(status: :skipped, error_message: reason)
  end

  def mark_failed!(reason)
    update!(status: :failed, failed_at: Time.current, error_message: reason)
  end
end
