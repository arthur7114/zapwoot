# Deploy EasyPanel — Chatwoot fork (WhatsApp reskin + Kanban) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Nota:** grande parte deste plano é operação manual na UI do EasyPanel. Passos de UI têm verificação explícita no lugar de teste automatizado. Passos de git/shell trazem comandos exatos.

**Goal:** Colocar em produção, num EasyPanel existente, o fork do Chatwoot com reskin WhatsApp + Kanban + mensagens agendadas + pt_BR, buildando a imagem custom direto do Git.

**Architecture:** 4 serviços num projeto EasyPanel — `rails` (web, build via `docker/Dockerfile`), `sidekiq` (worker, mesmo Dockerfile), `postgres` (`pgvector/pgvector:pg16`), `redis` (`redis:alpine`). EasyPanel builda do repositório GitHub a cada push na branch de deploy. Banco novo, schema criado via `db:chatwoot_prepare`. Anexos em volume local `/app/storage`.

**Tech Stack:** Ruby 3.4 / Rails, Sidekiq, PostgreSQL 16 + pgvector, Redis, Vite/Vue, Docker, EasyPanel.

## Global Constraints

- Imagem buildada **do fork**, nunca `chatwoot/chatwoot:latest` (o fork altera frontend e backend).
- Branch de deploy: `claude/deploy-easypanel-342f9a` (recebe merge de `feature/whatsapp-reskin`).
- Dockerfile de build: `docker/Dockerfile`, contexto de build `.` (raiz do repo).
- Postgres **obrigatoriamente** com extensão pgvector → imagem `pgvector/pgvector:pg16`.
- `rails` e `sidekiq` compartilham exatamente o mesmo conjunto de env vars.
- `SECRET_KEY_BASE` alfanumérico, sem símbolos especiais.
- Instalação nova: rodar `db:chatwoot_prepare` uma vez antes de considerar o deploy pronto.
- Segredos (senhas, SECRET_KEY_BASE) nunca commitados no repo.

---

### Task 1: Consolidar código da reskin na branch de deploy

**Files:**
- Modify: (nenhum arquivo editado à mão — é um merge de branch)

**Interfaces:**
- Consumes: branch `feature/whatsapp-reskin` (86 commits à frente do develop), branch `claude/deploy-easypanel-342f9a`.
- Produces: branch `claude/deploy-easypanel-342f9a` contendo todo o código do fork (kanban, reskin, migrations `pipeline_stages` / `scheduled_messages`, pt_BR) + o design/plano de deploy, empurrada pro GitHub.

- [ ] **Step 1: Confirmar branch atual e árvore limpa**

```bash
git status
git branch --show-current
```
Expected: branch `claude/deploy-easypanel-342f9a`, working tree clean (só os docs de spec/plan commitados).

- [ ] **Step 2: Merge da reskin na branch de deploy**

```bash
git merge --no-ff feature/whatsapp-reskin -m "chore: merge whatsapp-reskin into easypanel deploy branch"
```
Expected: merge conclui. Se houver conflito, resolver antes de seguir (a branch de deploy só tem os docs adicionais, então conflito é improvável).

- [ ] **Step 3: Verificar que o código do fork chegou**

```bash
git log --oneline -5
ls app/models/pipeline_stage.rb app/models/scheduled_message.rb
ls db/migrate/*create_pipeline_stages* db/migrate/*create_scheduled_messages*
```
Expected: os 4 arquivos existem; o log mostra os commits da reskin.

- [ ] **Step 4: Confirmar que o Dockerfile e entrypoints existem na branch**

```bash
ls docker/Dockerfile docker/entrypoints/rails.sh
```
Expected: ambos existem.

- [ ] **Step 5: Push da branch pro GitHub**

```bash
git push -u origin claude/deploy-easypanel-342f9a
```
Expected: branch publicada em `origin`. (EasyPanel vai buildar a partir dela.)

---

### Task 2: Preparar segredos e conectar o repositório no EasyPanel

**Files:**
- Create (local, fora do repo): anotar segredos gerados no gerenciador de senhas — **não commitar**.

**Interfaces:**
- Consumes: repositório GitHub do fork; acesso admin ao EasyPanel.
- Produces: `SECRET_KEY_BASE`, senha do Postgres e senha do Redis geradas; projeto criado no EasyPanel; GitHub conectado (se repo privado).

- [ ] **Step 1: Gerar SECRET_KEY_BASE**

```bash
openssl rand -hex 64
```
Guardar o valor no gerenciador de senhas com o rótulo `chatwoot SECRET_KEY_BASE`.

- [ ] **Step 2: Gerar senhas de Postgres e Redis**

```bash
openssl rand -hex 24   # senha do Postgres
openssl rand -hex 24   # senha do Redis
```
Guardar ambas no gerenciador de senhas.

- [ ] **Step 3: Criar o projeto no EasyPanel**

Na UI do EasyPanel: **Projects → Create Project**, nome `chatwoot`.
Expected: projeto `chatwoot` aparece na lista.

- [ ] **Step 4: (Se repo privado) conectar o GitHub ao EasyPanel**

Na UI: **Settings → GitHub** (ou "Git" no serviço) → conectar via GitHub App ou adicionar deploy key. Autorizar acesso ao repositório do fork.
Expected: o repositório do fork aparece selecionável ao criar um App service.

---

### Task 3: Criar o serviço Postgres (pgvector)

**Files:** — (operação de UI no EasyPanel)

**Interfaces:**
- Consumes: senha do Postgres gerada na Task 2.
- Produces: serviço `postgres` rodando; host interno (ex.: `chatwoot_postgres`), db `chatwoot`, usuário `postgres`.

- [ ] **Step 1: Criar serviço de banco**

No projeto `chatwoot`: **Create Service → Postgres** (ou App com imagem custom). Definir a imagem como `pgvector/pgvector:pg16` (não a imagem padrão do EasyPanel — precisamos do pgvector).

- [ ] **Step 2: Configurar credenciais e volume**

Definir: `POSTGRES_DB=chatwoot`, `POSTGRES_USER=postgres`, `POSTGRES_PASSWORD=<senha gerada>`. Garantir volume persistente montado em `/var/lib/postgresql/data`. Não expor porta pública.

- [ ] **Step 3: Deploy e verificação**

Fazer deploy do serviço. Abrir o console/terminal do serviço postgres e rodar:
```bash
psql -U postgres -d chatwoot -c "CREATE EXTENSION IF NOT EXISTS vector; SELECT extname FROM pg_extension WHERE extname='vector';"
```
Expected: retorna `vector` — confirma que a imagem suporta pgvector. (O Chatwoot também habilita a extensão nas migrations, mas isto confirma a imagem certa.)

- [ ] **Step 4: Anotar o host interno**

Anotar o hostname interno do serviço postgres exibido pelo EasyPanel (usado em `POSTGRES_HOST`).

---

### Task 4: Criar o serviço Redis

**Files:** — (operação de UI no EasyPanel)

**Interfaces:**
- Consumes: senha do Redis gerada na Task 2.
- Produces: serviço `redis` rodando; host interno; `REDIS_URL` + `REDIS_PASSWORD`.

- [ ] **Step 1: Criar serviço Redis**

No projeto `chatwoot`: **Create Service → Redis** (imagem `redis:alpine`), com senha = senha do Redis gerada. Garantir volume persistente em `/data`. Não expor porta pública.

- [ ] **Step 2: Deploy e verificação**

Deploy do serviço. No console do serviço redis:
```bash
redis-cli -a "<senha do redis>" ping
```
Expected: `PONG`.

- [ ] **Step 3: Anotar host interno e montar REDIS_URL**

Anotar o hostname interno. Montar `REDIS_URL=redis://<host-interno>:6379` (a senha vai em `REDIS_PASSWORD` separada).

---

### Task 5: Criar o serviço `rails` (web) buildando do Git

**Files:**
- Build source: `docker/Dockerfile` (contexto `.`), branch `claude/deploy-easypanel-342f9a`.

**Interfaces:**
- Consumes: repo GitHub conectado (Task 2), postgres (Task 3), redis (Task 4), todos os segredos.
- Produces: serviço `rails` rodando, exposto no domínio com SSL na porta 3000.

- [ ] **Step 1: Criar App service a partir do GitHub**

**Create Service → App**, nome `rails`. Source = GitHub → repositório do fork → branch `claude/deploy-easypanel-342f9a`.

- [ ] **Step 2: Configurar build por Dockerfile**

Build method = **Dockerfile**. Dockerfile path = `docker/Dockerfile`. Build context = `.` (raiz do repo).

- [ ] **Step 3: Definir entrypoint, command e porta**

- Entrypoint: `docker/entrypoints/rails.sh`
- Command: `bundle exec rails s -p 3000 -b 0.0.0.0`
- Porta interna: `3000`

- [ ] **Step 4: Definir as variáveis de ambiente**

Colar todas (substituindo os `<...>`):
```
SECRET_KEY_BASE=<hex gerado>
FRONTEND_URL=https://<seu-dominio>
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker
RAILS_LOG_TO_STDOUT=true
POSTGRES_HOST=<host interno postgres>
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=<senha postgres>
POSTGRES_DATABASE=chatwoot
REDIS_URL=redis://<host interno redis>:6379
REDIS_PASSWORD=<senha redis>
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
ACTIVE_STORAGE_SERVICE=local
SMTP_ADDRESS=<host smtp>
SMTP_PORT=587
SMTP_USERNAME=<usuario smtp>
SMTP_PASSWORD=<senha smtp>
MAILER_SENDER_EMAIL=Chatwoot <no-reply@seu-dominio>
```

- [ ] **Step 5: Montar o volume de storage**

Adicionar volume persistente montado em `/app/storage` (anexos do Active Storage).

- [ ] **Step 6: Configurar domínio e SSL**

Na aba **Domains** do serviço `rails`: adicionar o domínio, apontar pra porta `3000`, habilitar SSL (Let's Encrypt do EasyPanel).

- [ ] **Step 7: Deploy (primeiro build)**

Disparar deploy. Acompanhar os logs de build.
Expected: multi-stage builda; o estágio de frontend compila o Vite (kanban/reskin) sem erro; imagem finaliza. O container `rails` sobe e os logs mostram Puma escutando na 3000. (Erros de conexão de banco aqui são resolvidos na Task 7 — o schema ainda não existe.)

---

### Task 6: Criar o serviço `sidekiq` (worker)

**Files:**
- Build source: mesmo repo/branch e `docker/Dockerfile` do `rails`.

**Interfaces:**
- Consumes: mesmo repo/branch, mesmos segredos e hosts que o `rails`.
- Produces: serviço `sidekiq` processando a fila de jobs.

- [ ] **Step 1: Criar App service `sidekiq`**

**Create Service → App**, nome `sidekiq`. Source = mesmo repositório GitHub, branch `claude/deploy-easypanel-342f9a`, build method Dockerfile, Dockerfile path `docker/Dockerfile`, contexto `.`.

- [ ] **Step 2: Definir command (sem porta, sem domínio)**

- Command: `bundle exec sidekiq -C config/sidekiq.yml`
- Não expor porta nem domínio.
- Entrypoint: pode manter o default do Dockerfile (não precisa do `rails.sh`); se o EasyPanel exigir um, usar `docker/entrypoints/rails.sh` — ele apenas espera o Postgres e faz `exec` do command.

- [ ] **Step 3: Copiar as mesmas env vars do `rails`**

Colar exatamente o mesmo bloco de env vars da Task 5, Step 4. (Sidekiq precisa de banco e redis.) Não precisa do volume `/app/storage`.

- [ ] **Step 4: Deploy**

Disparar deploy. Acompanhar logs.
Expected: build reaproveita cache; container sobe; logs do Sidekiq mostram conexão ao Redis e "Booted Rails ... in production". Erros de schema aqui são normais até a Task 7.

---

### Task 7: Inicializar o banco (primeiro boot) e verificar o deploy

**Files:** — (comando no console do serviço `rails`)

**Interfaces:**
- Consumes: serviços `rails`, `sidekiq`, `postgres`, `redis` no ar.
- Produces: schema do Chatwoot criado com as migrations do fork; app funcional.

- [ ] **Step 1: Rodar o prepare do banco**

No console/terminal do serviço `rails` no EasyPanel:
```bash
bundle exec rails db:chatwoot_prepare
```
Expected: cria o schema e roda todas as migrations, incluindo `create_pipeline_stages`, `create_scheduled_messages` e `add_pipeline_stage_index_to_conversations`, sem erro.

- [ ] **Step 2: Confirmar as tabelas do fork**

Ainda no console do `rails`:
```bash
bundle exec rails runner "puts ActiveRecord::Base.connection.tables.grep(/pipeline_stages|scheduled_messages/).inspect"
```
Expected: `["pipeline_stages", "scheduled_messages"]` (ordem pode variar).

- [ ] **Step 3: Reiniciar `rails` e `sidekiq`**

Reiniciar os dois serviços no EasyPanel pra que subam já com o schema pronto.
Expected: logs sem erros de banco; Puma e Sidekiq estáveis.

- [ ] **Step 4: Verificar a aplicação no navegador**

Abrir `https://<seu-dominio>`.
Expected: tela de onboarding/login do Chatwoot com o **reskin WhatsApp** aplicado. Criar a conta admin inicial.

- [ ] **Step 5: Verificar as features do fork**

Logado como admin, confirmar:
- Board **Kanban** (funil) carrega.
- Página de **settings de pipeline stages** permite criar/editar estágios.
- **Agendamento de mensagem** aparece na conversa e agenda sem erro de i18n.
- UI disponível em **pt_BR**.

- [ ] **Step 6: Verificar persistência de anexos**

Enviar uma mensagem com anexo numa conversa de teste, reiniciar o serviço `rails`, e confirmar que o anexo continua acessível.
Expected: anexo persiste (volume `/app/storage` ok).

- [ ] **Step 7: Verificar deploy automático**

Fazer um commit trivial na branch de deploy e `git push`.
```bash
git commit --allow-empty -m "chore: trigger easypanel redeploy" && git push
```
Expected: EasyPanel detecta o push e dispara rebuild automático do `rails` (e do `sidekiq`, se configurado com auto-deploy).

---

## Notas de operação (pós-deploy)

- **Deploys futuros com migrations novas:** após o rebuild, rodar no console do `rails`: `bundle exec rails db:migrate`.
- **Backups:** configurar backup periódico do volume/DB do Postgres (recomendado; fora do escopo deste plano inicial).
- **Canais de WhatsApp:** configurar depois pela UI do Chatwoot (Inboxes → Add Inbox).
- **Storage S3/R2:** migração futura possível trocando `ACTIVE_STORAGE_SERVICE` e as credenciais correspondentes.
