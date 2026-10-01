namespace :pipeline_stages do
  desc 'Cria/renomeia as etapas do funil (kanban). ACCOUNT_ID=1 limita a uma conta; DRY_RUN=1 só mostra o plano'
  task sync: :environment do
    accounts = ENV['ACCOUNT_ID'].present? ? Account.where(id: ENV['ACCOUNT_ID']) : Account.all
    accounts.find_each { |account| PipelineStages::SyncService.new(account: account, dry_run: ENV['DRY_RUN'].present?).perform }
  end
end
