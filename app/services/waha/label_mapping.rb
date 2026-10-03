# Maps WhatsApp Business labels to pipeline stages by name. Labels that are not
# a stage become plain conversation labels; WhatsApp's built-in lists are ignored.
class Waha::LabelMapping
  STAGE_ALIASES = {
    'orcamento pendente' => 'aguardando orcamento',
    'visitas edson' => 'visita edson'
  }.freeze
  SYSTEM_LABELS = ['favoritos', 'nao lidas', 'grupos'].freeze
  # WhatsApp prefixes its default labels (Lead, Favoritos...) with this invisible mark.
  LEFT_TO_RIGHT_MARK = "\u200e".freeze

  def self.normalize(name)
    key = I18n.transliterate(name.to_s.delete(LEFT_TO_RIGHT_MARK)).downcase.squish
    STAGE_ALIASES.fetch(key, key)
  end

  def initialize(account)
    @account = account
    @stages_by_key = account.pipeline_stages.index_by { |stage| self.class.normalize(stage.title) }
  end

  def stage_for(label_name)
    @stages_by_key[self.class.normalize(label_name)]
  end

  def system?(label_name)
    SYSTEM_LABELS.include?(self.class.normalize(label_name))
  end

  # Reuses an existing conversation label with the same name ignoring accents ("Condomínio" -> condominio).
  def conversation_label_title(label_name)
    key = self.class.normalize(label_name)
    @account.labels.find { |label| self.class.normalize(label.title.tr('_', ' ')) == key }&.title ||
      label_name.delete(LEFT_TO_RIGHT_MARK).downcase.squish.tr(' ', '_')
  end

  # The WhatsApp label matching a conversation label title, if any.
  def whatsapp_label_for(title, whatsapp_labels)
    key = self.class.normalize(title.tr('_', ' '))
    whatsapp_labels.find { |label| self.class.normalize(label['name']) == key }
  end
end
