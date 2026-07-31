# == Schema Information
#
# Table name: scheduled_messages
#
#  id              :bigint           not null, primary key
#  content         :text             not null
#  private         :boolean          default(FALSE), not null
#  scheduled_at    :datetime         not null
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  sender_id       :bigint           not null
#
# Indexes
#
#  index_scheduled_messages_on_account_id       (account_id)
#  index_scheduled_messages_on_conversation_id  (conversation_id)
#  index_scheduled_messages_on_scheduled_at     (scheduled_at)
#  index_scheduled_messages_on_sender_id        (sender_id)
#
class ScheduledMessage < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'

  enum status: { pending: 0, processing: 1, completed: 2, canceled: 3, failed: 4 }

  validates :content, presence: true
  validates :scheduled_at, presence: true
  validate :scheduled_at_cannot_be_in_the_past, on: :create

  scope :due, -> { pending.where(scheduled_at: ..Time.current) }

  def trigger!
    return unless mark_processing!

    send_message!
    completed!
  rescue StandardError => e
    failed!
    raise e
  end

  private

  def scheduled_at_cannot_be_in_the_past
    return if scheduled_at.blank? || scheduled_at > Time.current

    errors.add(:scheduled_at, 'must be in the future')
  end

  def mark_processing!
    # Multiple scheduler jobs can pick the same due message; lock before flipping status to avoid duplicate sends.
    with_lock do
      next false unless pending?

      processing!
      true
    end
  end

  def send_message!
    Messages::MessageBuilder.new(sender, conversation, message_params).perform
  end

  def message_params
    { content: content, private: self[:private] }
  end
end
