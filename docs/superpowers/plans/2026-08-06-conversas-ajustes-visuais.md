# Ajustes Visuais de Conversas + Campanha por Etapa + Limpeza de Seed — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplificar a UI de conversas do zapwoot (aba "Todas", painel direito enxuto), adicionar filtro por etapa de kanban em campanhas WhatsApp, ativar ingestão de ecos do celular e limpar dados de seed do banco de produção.

**Architecture:** Fork do Chatwoot (Rails + Vue 3 + Vuex + Tailwind). O código em produção é a branch `deploy/main` do remote `zapwoot`; o Easypanel rebuilda automaticamente a cada push. Frontend em `app/javascript/dashboard`, backend Rails padrão Chatwoot.

**Tech Stack:** Ruby on Rails, Vue 3 (script setup + Options API misto), Vuex, vue-i18n (en + pt_BR), RSpec, PostgreSQL.

## Global Constraints

- Repositório: `/Users/arthurbrito/Documents/Dev/Chatwoot` (NÃO o worktree do GD onde a sessão começou).
- Base de código: branch `deploy/main` do remote `zapwoot` (https://github.com/arthur7114/zapwoot.git). A branch local `feature/whatsapp-reskin` está DESATUALIZADA — não usar como base.
- Push final: `git push deploy main:main` — o Easypanel rebuilda sozinho no push.
- Toda string de UI nova precisa de chave i18n em `en` E `pt_BR`. A UI do cliente é pt_BR.
- Card da conversa (etapa + etiquetas + responsável) JÁ EXISTE no código deployado — não reimplementar; apenas verificar ao vivo (Task 8).
- Ingestão de ecos (`smb_message_echoes`) JÁ EXISTE no backend (`Webhooks::WhatsappEventsJob` + `Whatsapp::IncomingMessageBaseService` com `outgoing_echo`) — o trabalho é configuração na Meta (Task 7).
- Limpeza de seed é em BANCO DE PRODUÇÃO via Postgres direto: SEMPRE dry-run listando o que será apagado + aprovação explícita do Arthur + backup `pg_dump` antes de qualquer DELETE.
- A connection string do Postgres ainda não foi fornecida — pedir ao Arthur no início da Task 6.

---

### Task 1: Branch de trabalho

**Files:**
- Nenhum arquivo de código; só git.

**Interfaces:**
- Produces: branch local `main` apontando para `deploy/main`, onde todas as tasks seguintes commitam.

- [ ] **Step 1: Criar branch local a partir da deploy/main**

```bash
cd /Users/arthurbrito/Documents/Dev/Chatwoot
git fetch deploy main
git checkout -B main deploy/main
git status --short
```

Expected: `Switched to a new branch 'main'` (ou reset), working tree limpo, HEAD em `6bea64b`.

---

### Task 2: Aba "Todas" na lista de conversas

**Files:**
- Modify: `app/javascript/dashboard/i18n/locale/en/chatlist.json` (bloco `READ_STATUS_TABS`, ~linha 22)
- Modify: `app/javascript/dashboard/i18n/locale/pt_BR/chatlist.json` (bloco `READ_STATUS_TABS`, ~linha 22)
- Modify: `app/javascript/dashboard/components/ChatList.vue` (linhas 71, ~254-270, ~325-340)

**Interfaces:**
- Consumes: `activeReadTab` (ref), `baseConversationList` (computed), `isUnreadConversation(chat)` — já existem no ChatList.vue.
- Produces: aba `all` como default; nenhuma outra task depende disso.

- [ ] **Step 1: Adicionar chave i18n `all` no en**

Em `app/javascript/dashboard/i18n/locale/en/chatlist.json`, trocar:

```json
    "READ_STATUS_TABS": {
      "unread": "Unread",
      "read": "Read"
    },
```

por:

```json
    "READ_STATUS_TABS": {
      "all": "All",
      "unread": "Unread",
      "read": "Read"
    },
```

- [ ] **Step 2: Adicionar chave i18n `all` no pt_BR**

Em `app/javascript/dashboard/i18n/locale/pt_BR/chatlist.json`, trocar:

```json
    "READ_STATUS_TABS": {
      "unread": "Não lidas",
      "read": "Lidas"
    },
```

por:

```json
    "READ_STATUS_TABS": {
      "all": "Todas",
      "unread": "Não lidas",
      "read": "Lidas"
    },
```

- [ ] **Step 3: Default da aba = 'all'**

Em `app/javascript/dashboard/components/ChatList.vue` linha 71, trocar:

```js
const activeReadTab = ref('unread');
```

por:

```js
const activeReadTab = ref('all');
```

- [ ] **Step 4: Adicionar a aba na lista de tabs**

No mesmo arquivo, no computed `assigneeTabItems` (~linha 254), trocar:

```js
const assigneeTabItems = computed(() => {
  const unreadCount =
    baseConversationList.value.filter(isUnreadConversation).length;
  return [
    {
      key: 'unread',
      name: t('CHAT_LIST.READ_STATUS_TABS.unread'),
      count: unreadCount,
    },
    {
      key: 'read',
      name: t('CHAT_LIST.READ_STATUS_TABS.read'),
      count: baseConversationList.value.length - unreadCount,
    },
  ];
});
```

por:

```js
const assigneeTabItems = computed(() => {
  const unreadCount =
    baseConversationList.value.filter(isUnreadConversation).length;
  return [
    {
      key: 'all',
      name: t('CHAT_LIST.READ_STATUS_TABS.all'),
      count: baseConversationList.value.length,
    },
    {
      key: 'unread',
      name: t('CHAT_LIST.READ_STATUS_TABS.unread'),
      count: unreadCount,
    },
    {
      key: 'read',
      name: t('CHAT_LIST.READ_STATUS_TABS.read'),
      count: baseConversationList.value.length - unreadCount,
    },
  ];
});
```

- [ ] **Step 5: Não filtrar quando a aba for 'all'**

No computed `conversationList` (~linha 325), trocar:

```js
  if (!hasAppliedFiltersOrActiveFolders.value) {
    localConversationList = localConversationList.filter(conversation =>
      activeReadTab.value === 'unread'
        ? isUnreadConversation(conversation)
        : !isUnreadConversation(conversation)
    );

    if (activeSortBy.value === wootConstants.SORT_BY_TYPE.UNREAD) {
      localConversationList = sortByUnreadStatus(localConversationList);
    }
  }
```

por:

```js
  if (!hasAppliedFiltersOrActiveFolders.value) {
    if (activeReadTab.value !== 'all') {
      localConversationList = localConversationList.filter(conversation =>
        activeReadTab.value === 'unread'
          ? isUnreadConversation(conversation)
          : !isUnreadConversation(conversation)
      );
    }

    if (activeSortBy.value === wootConstants.SORT_BY_TYPE.UNREAD) {
      localConversationList = sortByUnreadStatus(localConversationList);
    }
  }
```

- [ ] **Step 6: Lint dos arquivos alterados**

```bash
cd /Users/arthurbrito/Documents/Dev/Chatwoot
pnpm eslint app/javascript/dashboard/components/ChatList.vue
```

Expected: sem erros (warnings pré-existentes são aceitáveis).

- [ ] **Step 7: Commit**

```bash
git add app/javascript/dashboard/components/ChatList.vue app/javascript/dashboard/i18n/locale/en/chatlist.json app/javascript/dashboard/i18n/locale/pt_BR/chatlist.json
git commit -m "feat(conversations): add 'Todas' tab as default alongside read/unread"
```

---

### Task 3: Painel direito enxuto — agente solto + notas + anexos

**Files:**
- Create: `app/javascript/dashboard/routes/dashboard/conversation/ConversationAssignee.vue`
- Modify: `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`
- Modify: `app/javascript/dashboard/composables/useUISettings.js` (linhas 4-15)

**Interfaces:**
- Consumes: `useAgentsList` composable, store actions `setCurrentChatAssignee`/`assignAgent`, componente `MultiselectDropdown` (`shared/components/ui/MultiselectDropdown.vue`), `ContactDetailsItem` (mesma pasta), `LabelBox.vue` (`./labels/LabelBox.vue`), padrão visual de `ConversationPipelineStage.vue`.
- Produces: componente `ConversationAssignee.vue` (sem props; lê `getSelectedChat` do store). O painel deixa de renderizar `conversation_actions`, `conversation_participants`, `conversation_info`, `contact_attributes`, `previous_conversation`.

**Nota de escopo:** a box "Ações da conversa" continha também as **etiquetas da conversa** (LabelBox). Como etiquetas são necessárias (aparecem no card e filtram campanha), elas viram uma seção solta abaixo do agente — decisão registrada na entrevista.

- [ ] **Step 1: Criar `ConversationAssignee.vue`**

Criar `app/javascript/dashboard/routes/dashboard/conversation/ConversationAssignee.vue` com o conteúdo completo:

```vue
<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import ContactDetailsItem from './ContactDetailsItem.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const { t } = useI18n();
const { agentsList } = useAgentsList(true, { includeAgentBots: true });

const currentChat = useMapGetter('getSelectedChat');
const currentUser = useMapGetter('getCurrentUser');

const assignedAgent = computed({
  get() {
    const assignee = currentChat.value.meta?.assignee;
    return (
      assignee && {
        ...assignee,
        assignee_type: currentChat.value.meta.assignee_type || 'User',
      }
    );
  },
  set(agent) {
    const agentId = agent ? agent.id : null;
    const assigneeType = agent ? agent.assignee_type || 'User' : null;
    store.dispatch('setCurrentChatAssignee', {
      conversationId: currentChat.value.id,
      assignee: agent,
      assigneeType,
    });
    store
      .dispatch('assignAgent', {
        conversationId: currentChat.value.id,
        agentId,
        assigneeType,
      })
      .then(() => {
        useAlert(t('CONVERSATION.CHANGE_AGENT'));
      });
  },
});

const showSelfAssign = computed(() => {
  if (!assignedAgent.value) return true;
  return (
    assignedAgent.value.id !== currentUser.value.id ||
    (assignedAgent.value.assignee_type || 'User') !== 'User'
  );
});

const onSelfAssign = () => {
  const {
    account_id,
    availability_status,
    available_name,
    email,
    id,
    name,
    role,
    avatar_url,
  } = currentUser.value;
  assignedAgent.value = {
    account_id,
    availability_status,
    available_name,
    email,
    id,
    name,
    role,
    thumbnail: avatar_url,
  };
};

const onClickAssignAgent = selectedItem => {
  if (
    assignedAgent.value?.id === selectedItem.id &&
    (assignedAgent.value?.assignee_type || 'User') ===
      (selectedItem.assignee_type || 'User')
  ) {
    assignedAgent.value = null;
  } else {
    assignedAgent.value = selectedItem;
  }
};
</script>

<template>
  <div class="px-4 py-2 border-b border-n-weak">
    <ContactDetailsItem
      compact
      :title="$t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL')"
    >
      <template #button>
        <NextButton
          v-if="showSelfAssign"
          link
          xs
          icon="i-lucide-arrow-right"
          class="!gap-1"
          :label="$t('CONVERSATION_SIDEBAR.SELF_ASSIGN')"
          @click="onSelfAssign"
        />
      </template>
    </ContactDetailsItem>
    <MultiselectDropdown
      :options="agentsList"
      :selected-item="assignedAgent"
      :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
      :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
      :no-search-result="
        $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
      "
      :input-placeholder="
        $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
      "
      @select="onClickAssignAgent"
    />
  </div>
</template>
```

- [ ] **Step 2: Atualizar imports do `ContactPanel.vue`**

Em `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`, remover estes imports:

```js
import ContactConversations from './ContactConversations.vue';
import ConversationAction from './ConversationAction.vue';
import ConversationParticipant from './ConversationParticipant.vue';
import ConversationInfo from './ConversationInfo.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
```

e adicionar (junto aos imports existentes):

```js
import ConversationAssignee from './ConversationAssignee.vue';
import ConversationLabels from './labels/LabelBox.vue';
import ContactDetailsItem from './ContactDetailsItem.vue';
```

- [ ] **Step 3: Remover computeds que ficaram órfãos**

No mesmo arquivo, remover (eram usados só pelo `ConversationInfo`):

```js
const conversationMetadataGetter = useMapGetter(
  'conversationMetadata/getConversationMetadata'
);
const currentConversationMetaData = computed(() =>
  conversationMetadataGetter.value(conversationId.value)
);
const conversationAdditionalAttributes = computed(
  () => currentConversationMetaData.value.additional_attributes || {}
);
```

e:

```js
const contactAdditionalAttributes = computed(
  () => contact.value.additional_attributes || {}
);
```

Manter `channelType`, `contact`, `contactId`, `conversationId` (usados por ContactInfo/notas).

- [ ] **Step 4: Filtrar itens salvos do uiSettings**

No mesmo arquivo, adicionar a constante antes do `onMounted` e ajustar o `onMounted`:

```js
const ALLOWED_SIDEBAR_ITEMS = [
  'macros',
  'contact_notes',
  'shared_files',
  'linear_issues',
  'shopify_orders',
];

onMounted(() => {
  conversationSidebarItems.value = conversationSidebarItemsOrder.value.filter(
    item => ALLOWED_SIDEBAR_ITEMS.includes(item.name)
  );
  getContactDetails();
  store.dispatch('attributes/get', 0);
  // Load integrations to ensure linear integration state is available
  store.dispatch('integrations/get', 'linear');
});
```

(O `onMounted` original só trocava a primeira linha: `conversationSidebarItems.value = conversationSidebarItemsOrder.value;`.)

- [ ] **Step 5: Template — agente e etiquetas soltos no topo**

No template do `ContactPanel.vue`, logo após `<ConversationPipelineStage v-if="currentChat.id" />`, adicionar:

```vue
    <ConversationAssignee v-if="currentChat.id" />
    <div v-if="currentChat.id" class="px-4 py-2 border-b border-n-weak">
      <ContactDetailsItem
        compact
        :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
      />
      <ConversationLabels :conversation-id="conversationId" />
    </div>
```

- [ ] **Step 6: Template — remover as seções descartadas**

Dentro do `<template #item="{ element }">` do Draggable, deletar integralmente os blocos:

1. `<div v-if="element.name === 'conversation_actions'" ...>` (AccordionItem CONVERSATION_ACTIONS + ConversationAction) — o bloco inteiro.
2. `<div v-else-if="element.name === 'conversation_participants'" ...>` — bloco inteiro.
3. `<div v-else-if="element.name === 'conversation_info'">` — bloco inteiro.
4. `<div v-else-if="element.name === 'contact_attributes'">` — bloco inteiro.
5. `<div v-else-if="element.name === 'previous_conversation'">` — bloco inteiro.

O primeiro bloco restante (`macros`, que é `<woot-feature-toggle v-else-if=...>`) passa a ser o primeiro branch: trocar seu `v-else-if` por `v-if`.

- [ ] **Step 7: Atualizar ordem default no `useUISettings.js`**

Em `app/javascript/dashboard/composables/useUISettings.js`, trocar:

```js
export const DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER = Object.freeze([
  { name: 'conversation_actions' },
  { name: 'macros' },
  { name: 'conversation_info' },
  { name: 'contact_attributes' },
  { name: 'contact_notes' },
  { name: 'shared_files' },
  { name: 'previous_conversation' },
  { name: 'conversation_participants' },
  { name: 'linear_issues' },
  { name: 'shopify_orders' },
]);
```

por:

```js
export const DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER = Object.freeze([
  { name: 'macros' },
  { name: 'contact_notes' },
  { name: 'shared_files' },
  { name: 'linear_issues' },
  { name: 'shopify_orders' },
]);
```

- [ ] **Step 8: Lint**

```bash
pnpm eslint app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue app/javascript/dashboard/routes/dashboard/conversation/ConversationAssignee.vue app/javascript/dashboard/composables/useUISettings.js
```

Expected: sem erros novos. Se acusar import não usado remanescente no ContactPanel, remover o import apontado.

- [ ] **Step 9: Commit**

```bash
git add app/javascript/dashboard/routes/dashboard/conversation/ConversationAssignee.vue app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue app/javascript/dashboard/composables/useUISettings.js
git commit -m "feat(conversation-sidebar): slim panel to assignee, labels, notes and files"
```

---

### Task 4: Campanha por etapa — backend (TDD)

**Files:**
- Create: `spec/factories/pipeline_stages.rb`
- Modify: `app/services/whatsapp/oneoff_campaign_service.rb` (métodos `perform`, `extract_audience_labels`, `process_audience`)
- Test: `spec/services/whatsapp/oneoff_campaign_service_spec.rb`

**Interfaces:**
- Consumes: `Campaign#audience` (jsonb array de `{ 'type' => 'Label'|'PipelineStage', 'id' => Integer }`), `PipelineStage` (has_many :conversations), `Contact.tagged_with`. O controller já permite `audience: [:type, :id]` — nada a mudar lá.
- Produces: semântica de audiência — labels (OR entre si) **E** etapas (contato precisa ter conversa atualmente numa das etapas). Só labels → comportamento atual. Só etapas → todos os contatos com conversa na etapa. O frontend (Task 5) envia `{ id, type: 'PipelineStage' }`.

- [ ] **Step 1: Criar factory de pipeline_stage**

Criar `spec/factories/pipeline_stages.rb`:

```ruby
FactoryBot.define do
  factory :pipeline_stage do
    account
    sequence(:title) { |n| "Stage #{n}" }
    color { '#009CE0' }
    sequence(:position) { |n| n }
  end
end
```

- [ ] **Step 2: Escrever os testes que falham**

Em `spec/services/whatsapp/oneoff_campaign_service_spec.rb`, dentro do `describe '#perform'` (seguir o padrão dos contexts existentes — o `before` do describe já stubba HTTP e o `channel`), adicionar:

```ruby
    context 'when audience includes pipeline stages' do
      let(:stage) { create(:pipeline_stage, account: account) }
      let!(:contact_in_stage) { create(:contact, account: account, phone_number: '+15551230001') }
      let!(:contact_outside_stage) { create(:contact, account: account, phone_number: '+15551230002') }

      before do
        conversation = create(:conversation, account: account, inbox: whatsapp_inbox,
                                             contact: contact_in_stage)
        conversation.update!(pipeline_stage_id: stage.id)
        campaign.update!(audience: [{ type: 'PipelineStage', id: stage.id }])
      end

      it 'sends template only to contacts with a conversation currently in the stage' do
        expect(whatsapp_channel).to receive(:send_template)
          .with(contact_in_stage.phone_number, anything, nil).once
        expect(whatsapp_channel).not_to receive(:send_template)
          .with(contact_outside_stage.phone_number, anything, nil)

        described_class.new(campaign: campaign).perform
      end
    end

    context 'when audience includes labels and pipeline stages' do
      let(:stage) { create(:pipeline_stage, account: account) }
      let!(:contact_with_both) { create(:contact, account: account, phone_number: '+15551230003') }
      let!(:contact_label_only) { create(:contact, account: account, phone_number: '+15551230004') }
      let!(:contact_stage_only) { create(:contact, account: account, phone_number: '+15551230005') }

      before do
        contact_with_both.update_labels([label1.title])
        contact_label_only.update_labels([label1.title])

        [contact_with_both, contact_stage_only].each do |contact|
          conversation = create(:conversation, account: account, inbox: whatsapp_inbox,
                                               contact: contact)
          conversation.update!(pipeline_stage_id: stage.id)
        end

        campaign.update!(audience: [
                           { type: 'Label', id: label1.id },
                           { type: 'PipelineStage', id: stage.id }
                         ])
      end

      it 'sends only to contacts matching label AND stage' do
        expect(whatsapp_channel).to receive(:send_template)
          .with(contact_with_both.phone_number, anything, nil).once
        expect(whatsapp_channel).not_to receive(:send_template)
          .with(contact_label_only.phone_number, anything, nil)
        expect(whatsapp_channel).not_to receive(:send_template)
          .with(contact_stage_only.phone_number, anything, nil)

        described_class.new(campaign: campaign).perform
      end
    end
```

Nota: se `send_template` for chamado com assinatura diferente nos testes existentes deste spec, espelhar a assinatura usada lá (os asserts existentes no arquivo são a referência canônica).

- [ ] **Step 3: Rodar e ver falhar**

```bash
cd /Users/arthurbrito/Documents/Dev/Chatwoot
bundle exec rspec spec/services/whatsapp/oneoff_campaign_service_spec.rb
```

Expected: os 2 contexts novos FALHAM (o service atual ignora `PipelineStage` e manda pra ninguém ou pros contatos errados). Os antigos passam.

- [ ] **Step 4: Implementar no service**

Em `app/services/whatsapp/oneoff_campaign_service.rb`, trocar:

```ruby
  def perform
    validate_campaign!
    process_audience(extract_audience_labels)
    campaign.completed!
  end
```

por:

```ruby
  def perform
    validate_campaign!
    process_audience
    campaign.completed!
  end
```

Trocar o método `extract_audience_labels`:

```ruby
  def extract_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end
```

por:

```ruby
  def audience_ids_of(type)
    campaign.audience.select { |audience| audience['type'] == type }.pluck('id')
  end

  def audience_label_titles
    campaign.account.labels.where(id: audience_ids_of('Label')).pluck(:title)
  end

  # Labels combine with OR between themselves; pipeline stages restrict the set
  # further (label AND stage) because a campaign aimed at a funnel stage should
  # not leak to contacts outside that stage.
  def audience_contacts
    scope = campaign.account.contacts

    labels = audience_label_titles
    scope = scope.tagged_with(labels, any: true) if labels.present?

    stage_ids = audience_ids_of('PipelineStage')
    if stage_ids.present?
      scope = scope.where(
        id: campaign.account.conversations.where(pipeline_stage_id: stage_ids).select(:contact_id)
      )
    end

    scope
  end
```

E trocar `process_audience`:

```ruby
  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    Rails.logger.info "Processing #{contacts.count} contacts for campaign #{campaign.id}"

    contacts.each { |contact| process_contact(contact) }

    Rails.logger.info "Campaign #{campaign.id} processing completed"
  end
```

por:

```ruby
  def process_audience
    contacts = audience_contacts
    Rails.logger.info "Processing #{contacts.count} contacts for campaign #{campaign.id}"

    contacts.each { |contact| process_contact(contact) }

    Rails.logger.info "Campaign #{campaign.id} processing completed"
  end
```

- [ ] **Step 5: Rodar e ver passar**

```bash
bundle exec rspec spec/services/whatsapp/oneoff_campaign_service_spec.rb
```

Expected: TODOS os exemplos passam (antigos + 2 novos).

- [ ] **Step 6: Commit**

```bash
git add app/services/whatsapp/oneoff_campaign_service.rb spec/services/whatsapp/oneoff_campaign_service_spec.rb spec/factories/pipeline_stages.rb
git commit -m "feat(campaigns): filter whatsapp campaign audience by kanban pipeline stage"
```

---

### Task 5: Campanha por etapa — frontend

**Files:**
- Modify: `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignForm.vue`
- Modify: `app/javascript/dashboard/i18n/locale/en/campaign.json`
- Modify: `app/javascript/dashboard/i18n/locale/pt_BR/campaign.json`

**Interfaces:**
- Consumes: getter `pipelineStages/getPipelineStages` (carregado globalmente pelo `Sidebar.vue` no mount — não precisa dispatch aqui), `TagMultiSelectComboBox` (já importado no form), backend da Task 4 aceitando `{ id, type: 'PipelineStage' }`.
- Produces: payload `audience` misto: `[{id, type: 'Label'}, ..., {id, type: 'PipelineStage'}, ...]`. Pelo menos um dos dois filtros é obrigatório.

- [ ] **Step 1: Chaves i18n**

Em `app/javascript/dashboard/i18n/locale/en/campaign.json`, localizar o bloco `CAMPAIGN.WHATSAPP.CREATE.FORM` (onde já existe `AUDIENCE`) e adicionar, como irmão de `AUDIENCE`:

```json
        "STAGES": {
          "LABEL": "Kanban stages",
          "PLACEHOLDER": "Select stages",
          "ERROR": "Select at least one label or stage"
        },
```

Em `app/javascript/dashboard/i18n/locale/pt_BR/campaign.json`, no bloco equivalente:

```json
        "STAGES": {
          "LABEL": "Etapas do kanban",
          "PLACEHOLDER": "Selecione as etapas",
          "ERROR": "Selecione ao menos uma etiqueta ou etapa"
        },
```

(Manter vírgulas JSON válidas conforme a posição inserida.)

- [ ] **Step 2: Estado + opções no form**

Em `WhatsAppCampaignForm.vue`:

No objeto `formState`, adicionar:

```js
  pipelineStages: useMapGetter('pipelineStages/getPipelineStages'),
```

No `initialState`, adicionar:

```js
  selectedStages: [],
```

Após o computed `audienceList`, adicionar:

```js
const stageList = computed(() =>
  mapToOptions(formState.pipelineStages.value, 'id', 'title')
);
```

- [ ] **Step 3: Validação "ao menos um dos dois"**

Trocar em `rules`:

```js
  selectedAudience: { required },
```

por remoção da linha (o objeto `rules` fica sem `selectedAudience`), e adicionar após `const v$ = useVuelidate(rules, state);`:

```js
const showAudienceError = ref(false);

const hasAudience = computed(
  () => state.selectedAudience.length > 0 || state.selectedStages.length > 0
);

watch(hasAudience, valid => {
  if (valid) showAudienceError.value = false;
});
```

Trocar no computed `formErrors`:

```js
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
```

por:

```js
  audience: showAudienceError.value
    ? t('CAMPAIGN.WHATSAPP.CREATE.FORM.STAGES.ERROR')
    : '',
```

Trocar `isSubmitDisabled`:

```js
const isSubmitDisabled = computed(
  () => v$.value.$invalid || !hasRequiredTemplateParams.value
);
```

por:

```js
const isSubmitDisabled = computed(
  () =>
    v$.value.$invalid || !hasAudience.value || !hasRequiredTemplateParams.value
);
```

E no `handleSubmit`, após `const isFormValid = await v$.value.$validate();`:

```js
  if (!hasAudience.value) {
    showAudienceError.value = true;
    return;
  }
```

- [ ] **Step 4: Payload com etapas**

No `prepareCampaignDetails`, trocar:

```js
    audience: state.selectedAudience?.map(id => ({
      id,
      type: 'Label',
    })),
```

por:

```js
    audience: [
      ...(state.selectedAudience?.map(id => ({ id, type: 'Label' })) ?? []),
      ...(state.selectedStages?.map(id => ({ id, type: 'PipelineStage' })) ??
        []),
    ],
```

- [ ] **Step 5: Campo no template**

No template, logo após o bloco do campo de audiência (o `<div>` que contém o `label for="audience"` e o `TagMultiSelectComboBox` de `audienceList`), adicionar um bloco equivalente:

```vue
    <div class="flex flex-col gap-1">
      <label for="stages" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.STAGES.LABEL') }}
      </label>
      <TagMultiSelectComboBox
        v-model="state.selectedStages"
        :options="stageList"
        :label="t('CAMPAIGN.WHATSAPP.CREATE.FORM.STAGES.LABEL')"
        :placeholder="t('CAMPAIGN.WHATSAPP.CREATE.FORM.STAGES.PLACEHOLDER')"
        :has-error="!!formErrors.audience"
        :message="formErrors.audience"
      />
    </div>
```

(Espelhar exatamente as props/classes do bloco de audiência existente — se o bloco real divergir do esboço acima, o bloco real é a referência.)

- [ ] **Step 6: Lint**

```bash
pnpm eslint "app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignForm.vue"
```

Expected: sem erros novos.

- [ ] **Step 7: Commit**

```bash
git add app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignForm.vue app/javascript/dashboard/i18n/locale/en/campaign.json app/javascript/dashboard/i18n/locale/pt_BR/campaign.json
git commit -m "feat(campaigns): kanban stage filter in whatsapp campaign form"
```

---

### Task 6: Limpeza da seed no banco de produção

**Files:**
- Nenhum arquivo de código commitado; scripts SQL rodados via `psql` (guardar cópias em scratchpad da sessão, não no repo).

**Interfaces:**
- Consumes: connection string do Postgres — **PEDIR AO ARTHUR** no início desta task (ele confirmou que tem e vai fornecer).
- Produces: banco sem dados de seed; conta real, inbox WhatsApp "GD", agentes e conversas reais intactos.

**Marcadores de seed conhecidos** (de `db/seeds.rb`): contas `Acme Inc`/`Acme Org`; usuário `john@acme.inc` (SuperAdmin "John"); inbox `Acme Support` (WebWidget, site `https://acme.inc`); contato `jane` / `jane@example.com`; canned response `start`. Pode haver mais lixo criado manualmente — o inventário decide.

- [ ] **Step 1: Obter a connection string e testar conexão**

Pedir a connection string ao Arthur. Depois:

```bash
psql "$CONN" -c "SELECT current_database(), version();"
```

Expected: conecta e retorna o nome do banco.

- [ ] **Step 2: Backup antes de qualquer coisa**

```bash
pg_dump "$CONN" --format=custom --file="$SCRATCHPAD/zapwoot-backup-$(date +%Y%m%d-%H%M%S).dump"
```

Expected: arquivo `.dump` criado com tamanho > 0. NÃO prosseguir sem backup.

- [ ] **Step 3: Inventário (dry-run) — rodar e mostrar ao Arthur**

```sql
-- contas
SELECT id, name, created_at FROM accounts ORDER BY id;
-- usuários
SELECT id, name, email, type FROM users ORDER BY id;
-- inboxes
SELECT i.id, i.account_id, i.name, i.channel_type FROM inboxes i ORDER BY i.account_id, i.id;
-- volume por conta
SELECT a.id, a.name,
  (SELECT count(*) FROM contacts c WHERE c.account_id = a.id) AS contacts,
  (SELECT count(*) FROM conversations cv WHERE cv.account_id = a.id) AS conversations
FROM accounts a ORDER BY a.id;
-- contatos suspeitos de seed na conta real (e-mails de exemplo)
SELECT id, account_id, name, email, phone_number FROM contacts
WHERE email ILIKE '%@example.com' OR email ILIKE '%@acme.inc' OR name IN ('jane', 'john');
```

Apresentar o resultado ao Arthur e obter a lista aprovada de: (a) IDs de contas fake inteiras, (b) IDs de inboxes fake na conta real, (c) IDs de contatos fake na conta real. **Não deletar nada sem essa aprovação explícita.**

- [ ] **Step 4: Deletar contas fake inteiras (IDs aprovados = `:fake_accounts`)**

O schema do Chatwoot não tem ON DELETE CASCADE na maioria das FKs — deletar em ordem, numa transação:

```sql
BEGIN;
DELETE FROM messages WHERE account_id IN (:fake_accounts);
DELETE FROM attachments WHERE account_id IN (:fake_accounts);
DELETE FROM reporting_events WHERE account_id IN (:fake_accounts);
DELETE FROM conversation_participants WHERE account_id IN (:fake_accounts);
DELETE FROM notifications WHERE account_id IN (:fake_accounts);
DELETE FROM csat_survey_responses WHERE account_id IN (:fake_accounts);
DELETE FROM conversations WHERE account_id IN (:fake_accounts);
DELETE FROM contact_inboxes WHERE inbox_id IN (SELECT id FROM inboxes WHERE account_id IN (:fake_accounts));
DELETE FROM contacts WHERE account_id IN (:fake_accounts);
DELETE FROM inbox_members WHERE inbox_id IN (SELECT id FROM inboxes WHERE account_id IN (:fake_accounts));
DELETE FROM campaigns WHERE account_id IN (:fake_accounts);
DELETE FROM inboxes WHERE account_id IN (:fake_accounts);
DELETE FROM channel_web_widgets WHERE account_id IN (:fake_accounts);
DELETE FROM channel_whatsapp WHERE account_id IN (:fake_accounts);
DELETE FROM channel_api WHERE account_id IN (:fake_accounts);
DELETE FROM canned_responses WHERE account_id IN (:fake_accounts);
DELETE FROM labels WHERE account_id IN (:fake_accounts);
DELETE FROM teams WHERE account_id IN (:fake_accounts);
DELETE FROM custom_attribute_definitions WHERE account_id IN (:fake_accounts);
DELETE FROM custom_filters WHERE account_id IN (:fake_accounts);
DELETE FROM webhooks WHERE account_id IN (:fake_accounts);
DELETE FROM pipeline_stages WHERE account_id IN (:fake_accounts);
DELETE FROM account_users WHERE account_id IN (:fake_accounts);
DELETE FROM accounts WHERE id IN (:fake_accounts);
COMMIT;
```

Se alguma FK bloquear com tabela não listada, adicionar o DELETE correspondente ANTES da linha que falhou e re-rodar (a transação garante atomicidade). Depois, deletar usuários que ficaram sem conta:

```sql
DELETE FROM users WHERE id NOT IN (SELECT DISTINCT user_id FROM account_users);
```

- [ ] **Step 5: Deletar inboxes/contatos fake dentro da conta real (IDs aprovados)**

```sql
BEGIN;
-- por inbox fake (:fake_inboxes)
DELETE FROM messages WHERE inbox_id IN (:fake_inboxes);
DELETE FROM conversations WHERE inbox_id IN (:fake_inboxes);
DELETE FROM contact_inboxes WHERE inbox_id IN (:fake_inboxes);
DELETE FROM inbox_members WHERE inbox_id IN (:fake_inboxes);
DELETE FROM campaigns WHERE inbox_id IN (:fake_inboxes);
DELETE FROM inboxes WHERE id IN (:fake_inboxes);
-- por contato fake (:fake_contacts)
DELETE FROM messages WHERE conversation_id IN (SELECT id FROM conversations WHERE contact_id IN (:fake_contacts));
DELETE FROM conversations WHERE contact_id IN (:fake_contacts);
DELETE FROM contact_inboxes WHERE contact_id IN (:fake_contacts);
DELETE FROM contacts WHERE id IN (:fake_contacts);
COMMIT;
```

- [ ] **Step 6: Verificação pós-limpeza**

Re-rodar o inventário do Step 3. Expected: só a conta real, inbox GD, agentes reais, contatos reais. Confirmar no app (recarregar o zapwoot) que a lista de caixas de entrada e contatos está limpa e as conversas reais continuam abrindo.

---

### Task 7: Ecos do WhatsApp Business (coexistência) — configuração Meta

**Files:**
- Nenhum código: `Webhooks::WhatsappEventsJob#message_echo_event?` e `Whatsapp::IncomingMessageBaseService` (param `outgoing_echo`) já tratam `smb_message_echoes` na base atual.

**Interfaces:**
- Consumes: acesso do Arthur ao painel Meta for Developers do app que serve a integração WhatsApp Cloud.
- Produces: mensagens enviadas pelo app WhatsApp Business do celular aparecem no zapwoot como mensagens outgoing.

- [ ] **Step 1: Confirmar provider da inbox GD**

Com o acesso Postgres da Task 6:

```sql
SELECT c.id, c.phone_number, c.provider FROM channel_whatsapp c;
```

Expected: `provider = 'whatsapp_cloud'`. Se for `default` (360dialog), ecos NÃO se aplicam — parar e reportar ao Arthur.

- [ ] **Step 2: Assinar o campo de webhook na Meta (ação do Arthur, guiada)**

No painel [Meta for Developers](https://developers.facebook.com) → app da integração → **WhatsApp > Configuration** (ou **Webhooks**) → seção Webhook fields → além de `messages` (já assinado), clicar **Subscribe** em **`smb_message_echoes`**.

Pré-requisito: o número precisa estar em modo coexistência (app do celular + Cloud API simultâneos). Se o celular já envia/recebe normalmente com a API ativa, já está.

- [ ] **Step 3: Verificar ponta a ponta**

Enviar uma mensagem de teste **pelo celular** (app WhatsApp Business) para um contato que tenha conversa no zapwoot. Expected: a mensagem aparece na conversa correspondente como mensagem enviada (outgoing), sem duplicar mensagens enviadas pelo próprio zapwoot. Se não aparecer, checar logs do container Rails no Easypanel por `smb_message_echoes`.

---

### Task 8: Deploy e verificação ao vivo

**Files:**
- Nenhum; push + verificação no app.

**Interfaces:**
- Consumes: todas as tasks de código commitadas na branch local `main`.
- Produces: build novo no ar via Easypanel.

- [ ] **Step 1: Push**

```bash
cd /Users/arthurbrito/Documents/Dev/Chatwoot
git log --oneline deploy/main..main
git push deploy main:main
```

Expected: push aceito; Easypanel inicia rebuild automaticamente.

- [ ] **Step 2: Aguardar build e verificar as abas**

Abrir o zapwoot no navegador. Expected: lista de conversas com 3 abas **Todas / Não lidas / Lidas**, "Todas" selecionada por padrão com a contagem total.

- [ ] **Step 3: Verificar painel direito**

Abrir uma conversa com o painel de contato aberto. Expected, de cima pra baixo: info do contato → **Etapa (kanban)** → **Agente atribuído** (com "Atribuir a mim") → **Etiquetas da conversa** → Notas do contato → Anexos. NÃO devem aparecer: Ações da conversa (box), prioridade, time, informações da conversa, atributos do contato, conversas anteriores, participantes.

- [ ] **Step 4: Verificar card da conversa (feature já existente)**

Em uma conversa de teste, definir uma etapa e uma etiqueta (agora pelo painel direito novo). Expected: o card na lista mostra no rodapé o chip da etapa (com cor) + etiquetas, e o responsável no canto superior direito. Se as conversas do print original continuarem sem rodapé, é porque não têm etapa/etiqueta definidas — comportamento correto.

- [ ] **Step 5: Verificar campanha**

Criar (sem disparar de verdade, ou com template de teste) uma campanha WhatsApp. Expected: formulário mostra "Etiquetas" E "Etapas do kanban"; criar com só etapa funciona; com nenhum dos dois, o submit bloqueia com a mensagem de erro.

- [ ] **Step 6: Reportar ao Arthur**

Resumo final com o que foi verificado, prints se útil, e estado da limpeza de seed e dos ecos.
