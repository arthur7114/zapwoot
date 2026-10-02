class Waha::PushStageLabelJob < ApplicationJob
  queue_as :default

  def perform(conversation)
    Waha::PushStageLabelService.new(conversation: conversation).perform
  end
end
