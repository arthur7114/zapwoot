class PipelineStages::SyncService
  # Ordem e cores oficiais do funil. `aliases` casam etapas que já existem com outro nome
  # para que elas sejam renomeadas em vez de duplicadas (as conversas ficam onde estão).
  DEFINITIONS = [
    { title: 'Lead', color: '#3B82F6', aliases: %w[lead leads novo novos] },
    { title: 'Medidas', color: '#F59E0B', aliases: ['aguardando medidas', 'aguardando medida'] },
    { title: 'Aguardando orçamento', color: '#8B5CF6', aliases: ['orçamento pendente', 'orcamento pendente', 'aguardando orcamento'] },
    { title: 'Orçamento enviado', color: '#06B6D4', aliases: ['orcamento enviado'] },
    { title: 'Visita técnica', color: '#F97316', aliases: ['visita tecnica', 'visitas técnicas', 'visitas tecnicas'] },
    { title: 'Visita Edson', color: '#EC4899', aliases: ['visitas edson'] },
    { title: 'Clientes', color: '#10B981', aliases: %w[cliente] },
    { title: 'Stand By', color: '#64748B', aliases: %w[standby stand-by] }
  ].freeze

  def initialize(account:, dry_run: false, output: $stdout)
    @account = account
    @dry_run = dry_run
    @output = output
  end

  def perform
    @output.puts "== Conta #{@account.id} (#{@account.name})#{' [DRY RUN]' if @dry_run}"
    remaining = @account.pipeline_stages.reorder(:position, :id).to_a

    DEFINITIONS.each_with_index { |definition, position| sync_definition(definition, position, remaining) }
    keep_leftovers_after_funnel(remaining)
  end

  private

  def sync_definition(definition, position, remaining)
    names = [definition[:title], *definition[:aliases]].map { |name| normalize(name) }
    stage = remaining.find { |candidate| names.include?(normalize(candidate.title)) }
    remaining.delete(stage)

    @output.puts "  #{position}. #{definition[:title]} -> #{stage ? "atualiza ##{stage.id} '#{stage.title}'" : 'cria'}"
    return if @dry_run

    (stage || @account.pipeline_stages.new).update!(title: definition[:title], color: definition[:color], position: position)
  end

  def keep_leftovers_after_funnel(remaining)
    remaining.each_with_index do |stage, index|
      @output.puts "  (fora do funil oficial, mantida) ##{stage.id} '#{stage.title}'"
      stage.update!(position: DEFINITIONS.size + index) unless @dry_run
    end
  end

  def normalize(name)
    name.downcase.strip
  end
end
