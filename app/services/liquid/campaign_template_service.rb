class Liquid::CampaignTemplateService
  DEFAULT_TIMEZONE = 'America/Sao_Paulo'.freeze

  pattr_initialize [:campaign!, :contact!]

  def call(message)
    process_liquid_in_content(message_drops, message)
  end

  private

  def message_drops
    {
      'contact' => ContactDrop.new(contact),
      'agent' => UserDrop.new(campaign.sender),
      'inbox' => InboxDrop.new(campaign.inbox),
      'account' => AccountDrop.new(campaign.account),
      'saudacao' => saudacao
    }
  end

  # Bom dia / Boa tarde / Boa noite according to the hour the message actually goes out,
  # in the campaign's send timezone.
  def saudacao
    zone = ActiveSupport::TimeZone[campaign.send_schedule&.dig('timezone').presence || DEFAULT_TIMEZONE]
    case Time.current.in_time_zone(zone).hour
    when 5..11 then 'Bom dia'
    when 12..17 then 'Boa tarde'
    else 'Boa noite'
    end
  end

  def process_liquid_in_content(drops, message)
    message = message.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
    template = Liquid::Template.parse(message)
    template.render(drops)
  rescue Liquid::Error
    message
  end
end
