class Waha::LabelEventJob < ApplicationJob
  queue_as :default

  def perform(event, payload)
    Waha::LabelEventService.new(event: event, payload: payload).perform
  end
end
