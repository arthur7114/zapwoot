# Spec — Interface estilo WhatsApp para o Chatwoot

Documento de especificação da visão. Consolidado após grelhamento (`/grill-me`).
Idioma do produto: PT-BR. Fork/customização sobre o Chatwoot OSS.

## 1. Visão geral

Transformar o Chatwoot numa ferramenta de atendimento comercial com a cara e a
leveza do WhatsApp Web, somando três capacidades de produto:

1. **Kanban / Funil customizável** baseado nas conversas (peça nova, greenfield).
2. **Agendamento de mensagens** (backend pronto; faltam políticas + UI fina).
3. **Quick Replies** (respostas rápidas — pronto, reaproveita Canned Responses).
4. **Reskin WhatsApp** (tema pronto; falta refinamento das bolhas/chat).

Onde o código vive hoje: worktree principal `/Users/arthurbrito/Documents/Dev/Chatwoot`,
branch `feature/whatsapp-reskin`, tudo **não commitado**. Mockup de referência:
`design/whatsapp-comercial.html`.

---

## 2. Feature 1 — Kanban / Funil customizável

A peça nova e a única incógnita real de produto. É a prioridade.

### 2.1 Decisões (do grelhamento)

| # | Decisão | Escolha |
|---|---------|---------|
| Estrutura | Quantos funis | **Um funil único por conta** |
| Coluna | O que representa | **Estágio de funil customizável** (não status, não label) |
| Relação com status | Acoplamento | **Totalmente independente** — arrastar só muda o estágio, nunca o `status` |
| Escopo do board | Quais conversas | **Só não-resolvidas** (open/pending/snoozed), com filtros no topo (inbox, atendente, label) |
| Entrada | Onde cai a conversa nova | **Primeira coluna**, automaticamente |
| Ordenação | Dentro da coluna | **Automática por `last_activity_at`** (mais recente no topo). Sem posição manual |
| Configuração | Quem edita colunas | **Só admin** (em Settings) |
| Apagar coluna com cards | Comportamento | **Move os cards pra primeira coluna** |
| Tempo real | Sincronização | **Completo**, via o pubsub `conversation.updated` que já existe |

### 2.2 Modelo de dados

Uma tabela nova + uma coluna na conversa.

**`pipeline_stages`** (nova)
- `id`
- `account_id` (FK, indexado) — funil é por conta
- `title` (string, presença obrigatória)
- `position` (integer) — ordem das colunas
- `color` (string, opcional) — cor do cabeçalho da coluna (toque WhatsApp/comercial)
- timestamps
- Índice: `(account_id, position)`

**`conversations.pipeline_stage_id`** (coluna nova)
- FK nullable pra `pipeline_stages`, `on_delete: :nullify`
- Indexado (filtro/agrupamento do board é por essa coluna)
- `nil` = conversa ainda sem estágio → tratada como "cai na primeira coluna" ao aparecer no board

**Semântica de entrada:** ao criar conversa (ou na primeira vez que entra no board),
se `pipeline_stage_id` for `nil`, resolve pra primeira coluna (`position` mínima) da conta.
Preferir resolução na leitura/apresentação a um hook pesado de criação, para não acoplar
o motor de criação de conversas ao funil.

**Independência do status:** mudar `pipeline_stage_id` **não** toca em `status`.
São dimensões ortogonais. O card mostra o status como selinho visual, só isso.

> Nota Enterprise (CLAUDE.md): manter em OSS, sem hardcode de plano. Se no futuro
> o Enterprise precisar estender (ex.: múltiplos funis por plano), usar
> `prepend_mod_with`/hooks — não fork.

### 2.3 API

Padrão dos controllers existentes (`Api::V1::Accounts::...`), com policies.

**Configuração de estágios (admin):**
- `GET    /api/v1/accounts/:account_id/pipeline_stages` — lista ordenada
- `POST   /api/v1/accounts/:account_id/pipeline_stages` — cria (`title`, `color`, `position`)
- `PATCH  /api/v1/accounts/:account_id/pipeline_stages/:id` — renomeia / recolore / reordena
- `DELETE /api/v1/accounts/:account_id/pipeline_stages/:id` — apaga; **move cards pra primeira coluna** antes de remover
- Autorização: admin da conta (seguir `PipelineStagePolicy`, espelhando LabelPolicy/TeamPolicy)

**Mover um card (qualquer agente):**
- Reusar o update de conversa existente para setar `pipeline_stage_id`
  (ex.: `PATCH .../conversations/:id` ou um endpoint fino dedicado
  `POST .../conversations/:id/pipeline_stage`). Preferir o fino, dedicado, para
  telemetria/permissão claras e para disparar o broadcast sem efeitos colaterais.
- Setar `pipeline_stage_id` dispara `conversation.updated` (tempo real, ver 2.5).

**Board data:** o board consome a lista de conversas já existente, filtrada por
não-resolvidas + filtros de topo, agrupando client-side por `pipeline_stage_id`.
Incluir `pipeline_stage_id` no payload da conversa (`conversation` jbuilder/serializer).

### 2.4 Frontend / UX

- **Nova view** de nível de topo na navegação (ao lado de Conversas), rota tipo
  `/app/accounts/:id/kanban`. Item no rail/sidebar com ícone.
- **Board**: colunas horizontais com scroll; cada coluna = estágio, com header
  (título + cor + contador). Cards = conversas (avatar, nome, última msg,
  selinho de status, atendente, labels). Visual leve estilo WhatsApp/comercial.
- **Drag & drop** entre colunas → chama o endpoint de mover → otimista + confirma.
- **Ordenação** dentro da coluna: por `last_activity_at` desc (sem drag de reordenar).
- **Filtros no topo**: inbox, atendente, label. Default: só não-resolvidas.
- **Config de colunas**: tela em Settings (admin) — criar, renomear, recolorir,
  reordenar (drag das colunas), apagar (com aviso de que os cards voltam pra 1ª coluna).
- **Branding**: usar `replaceInstallationName` onde houver texto com "Chatwoot".

### 2.5 Tempo real

- Mudança de `pipeline_stage_id` = update na conversa → evento `conversation.updated`
  no ActionCable que o front já escuta.
- O board escuta os mesmos eventos das listas de conversa:
  - conversa nova / entra no escopo → aparece na coluna do seu estágio (ou 1ª);
  - resolvida → sai do board;
  - card movido por outro agente → reposiciona na hora.
- Sem infra nova: pega carona no pubsub existente.

### 2.6 Fases de implementação

1. **Migration + model**: `pipeline_stages` + `conversations.pipeline_stage_id` +
   `has_many`/`belongs_to`. Regenerar annotations do schema.
2. **API de config** (CRUD de estágios) + policy admin + jbuilder views.
3. **API de mover** card + inclusão de `pipeline_stage_id` no payload da conversa.
4. **Board frontend** (view, colunas, cards, drag&drop, filtros, agrupamento).
5. **Settings** de configuração de colunas (admin).
6. **Tempo real** (fiar nos eventos existentes) + polimento visual WhatsApp.

---

## 3. Feature 2 — Agendamento de mensagens

Backend completo, com locking e validação (ver `app/models/scheduled_message.rb`).
Frontend fiado nesta sessão anterior. Políticas decididas:

| # | Política | Decisão |
|---|----------|---------|
| Editar agendamento | — | **Só cancelar** na v1 (editar = cancelar + recriar) |
| Conversa resolvida antes do envio | — | **Envia mesmo assim** (não reabre sozinha — comportamento atual do Chatwoot) |
| Fuso horário | — | Usuário escolhe no **local**, persiste em **UTC** |
| Limites (qtd pendente / horizonte futuro) | — | **Sem limite rígido** na v1 |

Peças existentes: `ScheduledMessage` (statuses pending/processing/completed/canceled/failed,
scope `due`, `trigger!` com row lock), controller index/create/destroy,
`ScheduledMessages::TriggerJob`, agendador em `TriggerScheduledItemsJob`, rota,
migration aplicada. Frontend: `ScheduleMessageModal.vue`, `ScheduledMessagesQueue.vue`,
botão relógio em `ReplyBottomPanel.vue`, wiring em `ReplyBox.vue`, `api/inbox/scheduledMessage.js`,
i18n `CONVERSATION.SCHEDULE_MESSAGE.*` (en + pt_BR).

**Pendências:** validação visual em navegador (só foi verificado via API/spec até agora).

---

## 4. Feature 3 — Quick Replies

**Pronto.** É uma tira (`QuickReplies.vue`) que mostra as 8 primeiras
**Canned Responses** da conta como pílulas clicáveis; clicar insere o conteúdo no editor.
Reaproveita 100% o sistema de canned responses existente — sem backend novo.
Sem decisões pendentes. Documentar como está.

---

## 5. Feature 4 — Reskin WhatsApp

**Nível escolhido: (B) — tema + refinamento dos componentes de conversa.**
Sem reescrever a navegação global (preserva a sidebar recolhível e o roteamento).

Já feito (tema):
- `assets/scss/_next-colors.scss` — escala `blue` inteira → verde (light+dark) + var `--chat-wallpaper`
- `theme/colors.js` — `brand: #008069`
- `tailwind.config.js` — padrão de background `chat-wallpaper`
- `MessageStatus.vue` — tick de lido `#53BDEB`
- `ChatListHeader.vue` — atalho de busca
- `helper/themeHelper.js` — esquema default → `light` (+ spec atualizada, 10/10)

A fazer (refinamento B), só em `components-next/message/*`:
- Bolhas mais arredondadas estilo WhatsApp, com alinhamento in/out claro.
- Papel de parede no fundo do chat (`MessageList.vue`).
- Header de conversa no estilo (cor/avatar/altura).
- Ticks/estados de entrega consistentes.

Bônus já entregue (fora do reskin): **sidebar recolhível** com botão chevron
descoberto no hover/focus (`components-next/sidebar/Sidebar.vue` + i18n
`SIDEBAR.COLLAPSE_SIDEBAR`/`EXPAND_SIDEBAR`).

---

## 6. Fora de escopo (v2+)

- Múltiplos funis/boards por conta.
- Acoplamento estágio↔status (ex.: coluna "Fechado" resolve a conversa).
- Reordenação manual de cards dentro da coluna (campo `position` na conversa).
- Editar mensagem agendada (hoje é cancelar + recriar).
- Limites de agendamento.
- Reescrita total do layout pra igualar o mockup pixel a pixel (opção C do reskin).

---

## 7. Ordem sugerida de execução

1. **Organizar os commits atuais** — hoje há 2+ features misturadas no working tree
   não commitado. Separar (Conventional Commits, sem citar "Claude"): reskin,
   agendamento, sidebar. Rodar `/code-review` antes.
2. **Kanban** (fases 2.6) — é o maior bloco de trabalho novo.
3. **Refinamento do reskin (B)** — bolhas/chat.
4. **Verificação em navegador** do agendamento (pendência da sessão anterior).

> Regra do repo: evitar specs (testes) a menos que pedido; i18n só em `en.yml`/`en.json`
> (+ `pt_BR` aqui por ser fork). Checar `enterprise/` ao mexer em core.
