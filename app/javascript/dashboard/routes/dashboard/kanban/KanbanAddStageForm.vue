<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
  layout: {
    type: String,
    default: 'inline',
    validator: value => ['inline', 'column'].includes(value),
  },
});

const emit = defineEmits(['confirm', 'cancel']);

const { t } = useI18n();

const title = ref('');
const input = ref(null);

const focus = () => input.value?.focus();

const handleConfirm = () => {
  const trimmed = title.value.trim();
  if (!trimmed) return;
  emit('confirm', trimmed);
};

defineExpose({ focus });
</script>

<template>
  <form
    class="flex items-center gap-2"
    :class="layout === 'column' ? 'flex-shrink-0 w-72' : ''"
    @submit.prevent="handleConfirm"
  >
    <input
      ref="input"
      v-model="title"
      type="text"
      :placeholder="t('KANBAN.ADD_STAGE.PLACEHOLDER')"
      class="!mb-0"
      :class="layout === 'column' ? 'grow' : '!w-40'"
    />
    <Button
      type="submit"
      sm
      :label="t('KANBAN.ADD_STAGE.CONFIRM')"
      :disabled="!title.trim() || isLoading"
      :is-loading="isLoading"
    />
    <Button
      type="button"
      sm
      faded
      slate
      :label="t('KANBAN.ADD_STAGE.CANCEL')"
      @click="emit('cancel')"
    />
  </form>
</template>
