<script setup>
import { STAGE_COLOR_PALETTE } from './constants';

defineProps({
  modelValue: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue']);
</script>

<template>
  <div class="flex flex-wrap items-center gap-2 mb-4">
    <button
      v-for="color in STAGE_COLOR_PALETTE"
      :key="color"
      type="button"
      class="rounded-full size-7 outline outline-2 outline-offset-2"
      :class="
        modelValue?.toLowerCase() === color.toLowerCase()
          ? 'outline-n-slate-12'
          : 'outline-transparent'
      "
      :style="{ backgroundColor: color }"
      :aria-label="color"
      :aria-pressed="modelValue?.toLowerCase() === color.toLowerCase()"
      @click="emit('update:modelValue', color)"
    />
    <input
      type="color"
      class="p-0 border-0 rounded-full cursor-pointer size-7 !mb-0"
      :value="modelValue || '#000000'"
      :aria-label="$t('PIPELINE_STAGE_MGMT.FORM.COLOR.CUSTOM')"
      @input="emit('update:modelValue', $event.target.value)"
    />
  </div>
</template>
