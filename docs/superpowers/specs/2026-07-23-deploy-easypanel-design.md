# Deploy do fork Chatwoot (WhatsApp reskin + Kanban) no EasyPanel

**Data:** 2026-07-23
**Branch de deploy:** `claude/deploy-easypanel-342f9a`

## Objetivo

Colocar em produção, num EasyPanel já existente, o fork do Chatwoot com as
customizações da branch `feature/whatsapp-reskin`: reskin visual estilo
WhatsApp, board de funil (Kanban), mensagens agendadas (`scheduled_messages`),
estágios de pipeline (`pipeline_stages`) e traduções pt_BR.

Como o fork altera **frontend (Vue) e backend (models, rotas, migrations)**, a
imagem pública `chatwoot/chatwoot:latest` não serve — é necessário buildar uma
imagem própria a partir do código do fork.

## Decisões (confirmadas)

| Tema | Decisão |
|------|---------|
| Build/entrega da imagem | EasyPanel builda direto do Git usando `docker/Dockerfile` |
| Postgres/Redis | Criados no próprio EasyPanel (Postgres com imagem `pgvector/pgvector:pg16`) |
| Dados | Instalação nova, banco zerado |
| Servidor | EasyPanel + domínio já prontos |
| Storage de anexos | Volume local no EasyPanel montado em `/app/storage` |
| Consolidação de código | Merge de `feature/whatsapp-reskin` → `claude/deploy-easypanel-342f9a`; EasyPanel builda dessa branch |

## Arquitetura de serviços (1 projeto no EasyPanel, 4 serviços)

```
                    ┌─────────────────────────────┐
   Internet ── 443 ─┤ EasyPanel proxy (SSL/domínio)│
                    └──────────────┬──────────────┘
                                   │ :3000
                    ┌──────────────▼──────────────┐
                    │ rails (App)                  │
                    │ build: docker/Dockerfile     │
                    │ cmd: rails s -p 3000         │
                    │ vol: /app/storage            │
                    └───────┬───────────────┬──────┘
                            │               │
              ┌─────────────▼───┐   ┌───────▼─────────┐
              │ postgres        │   │ redis           │
              │ pgvector:pg16   │   │ redis:alpine    │
              │ vol: pgdata     │   │ vol: redisdata  │
              └─────────────▲───┘   └───────▲─────────┘
                            │               │
                    ┌───────┴───────────────┴──────┐
                    │ sidekiq (App, mesma imagem)   │
                    │ build: docker/Dockerfile      │
                    │ cmd: sidekiq -C sidekiq.yml   │
                    └───────────────────────────────┘
```

### 1. `rails` — serviço web (App, source = GitHub)
- **Source:** repositório GitHub do fork, branch `claude/deploy-easypanel-342f9a`.
  Se o repo for privado, conectar via GitHub App / deploy key no EasyPanel.
- **Build:** método Dockerfile, arquivo `docker/Dockerfile`, contexto de build `.` (raiz).
- **Entrypoint:** `docker/entrypoints/rails.sh`
- **Command:** `bundle exec rails s -p 3000 -b 0.0.0.0`
- **Porta:** 3000 → exposta no domínio com SSL gerenciado pelo EasyPanel.
- **Volume:** `/app/storage` (anexos do Active Storage).
- **Deploy automático:** push na branch dispara rebuild.

### 2. `sidekiq` — worker de background (App, mesma source/Dockerfile)
- Mesma source e `docker/Dockerfile` do `rails` (o EasyPanel builda a partir do
  mesmo commit da branch; o cache de layers torna o segundo build barato).
- **Command:** `bundle exec sidekiq -C config/sidekiq.yml`
- Sem porta pública. Sem volume de storage (não serve anexos).
- Processa os jobs do fork: `TriggerScheduledItemsJob`,
  `ScheduledMessages::TriggerJob`, além dos jobs padrão do Chatwoot.

> Nota de trade-off: rails e sidekiq são dois App services que buildam
> separadamente a mesma imagem. É a opção mais simples e nativa da UI do
> EasyPanel. Alternativa (fora de escopo agora): usar o tipo "Compose" do
> EasyPanel com um único `build:` compartilhado entre os dois serviços.

### 3. `postgres`
- Imagem `pgvector/pgvector:pg16` (pgvector é exigido pelo Chatwoot).
- Volume persistente para `/var/lib/postgresql/data`.
- `POSTGRES_DB=chatwoot`, `POSTGRES_USER`, `POSTGRES_PASSWORD` fortes.
- Sem porta pública (acesso só interno pela rede do projeto).

### 4. `redis`
- Imagem `redis:alpine`, com `--requirepass`.
- Volume persistente para `/data`.
- Sem porta pública.

## Variáveis de ambiente

Definidas **iguais em `rails` e `sidekiq`** (as duas precisam acessar banco/redis):

| Variável | Valor |
|----------|-------|
| `SECRET_KEY_BASE` | gerar hex longo (`openssl rand -hex 64`), alfanumérico |
| `FRONTEND_URL` | `https://<seu-dominio>` |
| `RAILS_ENV` | `production` |
| `NODE_ENV` | `production` |
| `INSTALLATION_ENV` | `docker` |
| `RAILS_LOG_TO_STDOUT` | `true` |
| `POSTGRES_HOST` | nome interno do serviço postgres no EasyPanel |
| `POSTGRES_USERNAME` | usuário do postgres |
| `POSTGRES_PASSWORD` | senha do postgres |
| `POSTGRES_DATABASE` | `chatwoot` |
| `REDIS_URL` | `redis://<host-interno-redis>:6379` |
| `REDIS_PASSWORD` | senha do redis |
| `RAILS_MAX_THREADS` | `5` |
| `WEB_CONCURRENCY` | `2` (ajustar conforme RAM) |
| `ACTIVE_STORAGE_SERVICE` | `local` (padrão; usa `/app/storage`) |
| SMTP (`SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAILER_SENDER_EMAIL`) | provedor de e-mail — necessário para convites de agente e notificações |

## Primeiro boot (instalação nova)

O entrypoint `rails.sh` **não roda migrations** — só aguarda o Postgres e sobe o
servidor. Numa instalação zerada, rodar **uma vez** no console do serviço `rails`:

```
bundle exec rails db:chatwoot_prepare
```

Isso cria o schema e roda as migrations do fork (`create_pipeline_stages`,
`create_scheduled_messages`, `add_pipeline_stage_index_to_conversations`).

Em deploys futuros que incluam novas migrations, rodar `bundle exec rails db:migrate`.

## Verificação (critérios de sucesso)

1. Build da imagem conclui no EasyPanel (frontend Vite compila sem erro).
2. `rails` sobe e responde na URL com SSL; tela de signup/login do Chatwoot
   aparece com o **reskin WhatsApp** aplicado.
3. `sidekiq` conecta no Redis e fica processando (logs sem erro de conexão).
4. Criar conta admin inicial e confirmar que **board Kanban**, **settings de
   pipeline stages** e **agendamento de mensagens** aparecem e funcionam.
5. UI em **pt_BR** disponível.
6. Anexos persistem após restart do serviço `rails` (volume ok).

## Fora de escopo (agora)

- Storage S3/R2 (fica em volume local; migração é evolução futura).
- Configuração dos canais de WhatsApp (feita depois pela UI do Chatwoot).
- CI/registry externo (EasyPanel builda do Git).
- Backups automatizados do Postgres (recomendável, mas não neste deploy inicial).
