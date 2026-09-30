<script setup>
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';

defineProps({
  campaigns: {
    type: Array,
    required: true,
  },
  isLiveChatType: {
    type: Boolean,
    default: false,
  },
  showRunControls: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['edit', 'delete', 'pause', 'resume']);

const handleEdit = campaign => emit('edit', campaign);
const handleDelete = campaign => emit('delete', campaign);
const handlePause = campaign => emit('pause', campaign);
const handleResume = campaign => emit('resume', campaign);
</script>

<template>
  <div class="flex flex-col gap-4">
    <CampaignCard
      v-for="campaign in campaigns"
      :key="campaign.id"
      :title="campaign.title"
      :message="campaign.message"
      :is-enabled="campaign.enabled"
      :status="campaign.campaign_status"
      :sender="campaign.sender"
      :inbox="campaign.inbox"
      :scheduled-at="campaign.scheduled_at"
      :is-live-chat-type="isLiveChatType"
      :show-run-controls="showRunControls"
      :recipient-counts="campaign.recipient_counts"
      @edit="handleEdit(campaign)"
      @delete="handleDelete(campaign)"
      @pause="handlePause(campaign)"
      @resume="handleResume(campaign)"
    />
  </div>
</template>
