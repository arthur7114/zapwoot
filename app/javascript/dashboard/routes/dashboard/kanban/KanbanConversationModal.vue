<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import MessagesView from 'dashboard/components/widgets/conversation/MessagesView.vue';
import PipelineStageBadge from 'dashboard/components-next/Conversation/PipelineStageBadge.vue';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const getConversationById = useMapGetter('getConversationById');
const selectedChat = useMapGetter('getSelectedChat');

const isReady = computed(() => selectedChat.value.id === props.conversationId);
const contact = computed(() => selectedChat.value.meta?.sender || {});

onMounted(async () => {
  let chat = getConversationById.value(props.conversationId);
  if (!chat) {
    await store.dispatch('getConversation', props.conversationId);
    chat = getConversationById.value(props.conversationId);
  }
  if (chat) {
    await store.dispatch('setActiveChat', { data: chat });
  }
});

const openFull = () => {
  router.push(
    accountScopedRoute('inbox_conversation', {
      conversation_id: props.conversationId,
    })
  );
};

const onClose = () => {
  store.dispatch('clearSelectedState');
  emit('close');
};
</script>

<template>
  <woot-modal show size="medium" :show-close-button="false" @close="onClose">
    <div class="flex flex-col w-full h-[80vh]">
      <header
        class="flex items-center flex-shrink-0 gap-2 px-4 border-b h-14 border-n-weak"
      >
        <Avatar
          :name="contact.name || ''"
          :src="contact.thumbnail"
          :size="28"
        />
        <span class="font-medium truncate text-n-slate-12">
          {{ contact.name }}
        </span>
        <span class="flex-shrink-0 text-xs text-n-slate-10">
          {{ `#${conversationId}` }}
        </span>
        <PipelineStageBadge
          v-if="isReady"
          :stage-id="selectedChat.pipeline_stage_id"
        />
        <div class="flex items-center gap-1 ltr:ml-auto rtl:mr-auto">
          <Button
            ghost
            slate
            sm
            icon="i-lucide-expand"
            :label="$t('KANBAN.PREVIEW.OPEN_FULL')"
            @click="openFull"
          />
          <Button
            ghost
            slate
            sm
            icon="i-lucide-x"
            :aria-label="$t('KANBAN.PREVIEW.CLOSE')"
            @click="onClose"
          />
        </div>
      </header>
      <div class="flex flex-1 min-h-0">
        <MessagesView v-if="isReady" />
        <div v-else class="flex items-center justify-center w-full">
          <woot-loading-state :message="$t('KANBAN.PREVIEW.LOADING')" />
        </div>
      </div>
    </div>
  </woot-modal>
</template>
