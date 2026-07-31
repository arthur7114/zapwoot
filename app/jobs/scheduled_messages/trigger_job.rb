class ScheduledMessages::TriggerJob < ApplicationJob
  queue_as :low

  def perform(scheduled_message)
    scheduled_message.trigger!
  end
end
