class Waha::AddChatLabelsJob < ApplicationJob
  queue_as :low

  def perform(contact, titles)
    Waha::AddChatLabelsService.new(contact: contact, titles: titles).perform
  end
end
