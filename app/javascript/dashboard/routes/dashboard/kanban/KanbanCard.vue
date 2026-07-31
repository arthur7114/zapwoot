<script setup>
import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  stages: {
    type: Array,
    default: () => [],
  },
  currentStageId: {
    type: [Number, String],
    default: null,
  },
});

const emit = defineEmits(['open', 'move']);

const { t } = useI18n();

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee);
const lastMessage = computed(
  () => props.conversation.last_non_activity_message?.content || ''
);

const statusColorClass = computed(() => {
  return (
    {
      open: 'bg-n-teal-9',
      pending: 'bg-n-amber-9',
      snoozed: 'bg-n-slate-9',
    }[props.conversation.status] || 'bg-n-slate-9'
  );
});

const isMenuOpen = ref(false);
const triggerRef = ref(null);
const popoverRef = ref(null);

const { fixedPosition, updatePosition } = useDropdownPosition(
  triggerRef,
  popoverRef,
  isMenuOpen,
  { align: 'end' }
);

const moveMenuItems = computed(() =>
  props.stages
    .filter(stage => stage.id !== props.currentStageId)
    .map(stage => ({ label: stage.title, value: stage.id, action: 'move' }))
);

const focusTrigger = () => triggerRef.value?.querySelector('button')?.focus();

const openMenu = async () => {
  if (!moveMenuItems.value.length) return;
  isMenuOpen.value = true;
  await nextTick();
  updatePosition();
  popoverRef.value?.$el?.querySelector('button')?.focus();
};

const closeMenu = ({ refocus = false } = {}) => {
  isMenuOpen.value = false;
  if (refocus) focusTrigger();
};

const toggleMenu = () => (isMenuOpen.value ? closeMenu() : openMenu());

const handleClickOutside = event => {
  if (triggerRef.value?.contains(event.target)) return;
  closeMenu();
};

const onMoveAction = ({ value }) => {
  emit('move', {
    conversationId: props.conversation.id,
    pipelineStageId: value,
  });
  closeMenu();
};
</script>

<template>
  <div
    role="button"
    tabindex="0"
    class="group flex flex-col gap-2 p-3 bg-n-solid-1 border border-n-weak rounded-lg cursor-grab active:cursor-grabbing hover:border-n-brand focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-n-brand"
    @click="emit('open')"
    @keydown.enter.self.prevent="emit('open')"
    @keydown.space.self.prevent="emit('open')"
  >
    <div class="flex items-center gap-2 min-w-0">
      <Avatar :name="contact.name || ''" :src="contact.thumbnail" :size="24" />
      <span class="min-w-0 text-sm font-medium text-n-slate-12 truncate">
        {{ contact.name }}
      </span>
      <span
        class="flex-shrink-0 size-2 rounded-full ltr:ml-auto rtl:mr-auto"
        :class="statusColorClass"
      />
      <div
        v-if="moveMenuItems.length"
        ref="triggerRef"
        class="relative flex-shrink-0"
        @click.stop
      >
        <Button
          icon="i-lucide-ellipsis-vertical"
          ghost
          slate
          xs
          class="!size-6 opacity-0 group-hover:opacity-100 focus-visible:opacity-100"
          :class="{ '!opacity-100': isMenuOpen }"
          :aria-label="t('KANBAN.CARD.MOVE_LABEL')"
          @click="toggleMenu"
        />
        <TeleportWithDirection>
          <DropdownMenu
            v-if="isMenuOpen"
            ref="popoverRef"
            v-on-click-outside="handleClickOutside"
            :menu-items="moveMenuItems"
            :class="fixedPosition.class"
            :style="fixedPosition.style"
            class="w-52 !fixed"
            @action="onMoveAction"
            @keydown.escape="closeMenu({ refocus: true })"
          />
        </TeleportWithDirection>
      </div>
    </div>
    <p v-if="lastMessage" class="text-xs text-n-slate-11 line-clamp-2">
      {{ lastMessage }}
    </p>
    <div class="flex items-center justify-between">
      <span class="text-xs text-n-slate-10">#{{ conversation.id }}</span>
      <div class="flex items-center gap-1">
        <Avatar
          v-if="assignee"
          :name="assignee.name"
          :src="assignee.thumbnail"
          :size="18"
        />
        <span v-else class="text-xs text-n-slate-10">
          {{ t('KANBAN.CARD.UNASSIGNED') }}
        </span>
      </div>
    </div>
  </div>
</template>
