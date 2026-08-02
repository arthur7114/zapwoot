<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Spinner from 'shared/components/Spinner.vue';

const props = defineProps({
  existingAttachments: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:signedIds', 'update:deletedIds']);

const store = useStore();
const { t } = useI18n();

const keptExisting = ref([...props.existingAttachments]);
const removedExistingIds = ref([]);
const newFiles = ref([]);
const isUploading = ref(false);

const attachments = computed(() => [
  ...keptExisting.value.map(file => ({
    key: `existing-${file.id}`,
    name: file.filename,
    size: file.byte_size,
    url: file.file_url,
    existingId: file.id,
  })),
  ...newFiles.value.map(file => ({
    key: `new-${file.blobId}`,
    name: file.name,
    size: file.size,
    url: file.fileUrl,
    blobId: file.blobId,
  })),
]);

const formatSize = bytes => {
  if (!bytes) return '';
  const kb = bytes / 1024;
  if (kb < 1024) return `${Math.round(kb)} KB`;
  return `${(kb / 1024).toFixed(1)} MB`;
};

const emitSignedIds = () => {
  emit(
    'update:signedIds',
    newFiles.value.map(file => file.blobId)
  );
};

const onChangeFiles = async event => {
  const files = Array.from(event.target.files || []);
  event.target.value = '';
  if (!files.length) return;

  isUploading.value = true;
  await Promise.all(
    files.map(async file => {
      try {
        const uploaded = await store.dispatch(
          'cannedResponse/uploadAttachment',
          file
        );
        newFiles.value.push(uploaded);
      } catch (error) {
        useAlert(t('CANNED_MGMT.ATTACHMENTS.UPLOAD_ERROR'));
      }
    })
  );
  isUploading.value = false;
  emitSignedIds();
};

const removeAttachment = attachment => {
  if (attachment.existingId) {
    keptExisting.value = keptExisting.value.filter(
      file => file.id !== attachment.existingId
    );
    removedExistingIds.value.push(attachment.existingId);
    emit('update:deletedIds', removedExistingIds.value);
  } else {
    newFiles.value = newFiles.value.filter(
      file => file.blobId !== attachment.blobId
    );
    emitSignedIds();
  }
};
</script>

<template>
  <div class="w-full">
    <label>{{ $t('CANNED_MGMT.ATTACHMENTS.LABEL') }}</label>
    <ul
      v-if="attachments.length"
      class="flex flex-col gap-1 p-0 m-0 mb-2 list-none"
    >
      <li
        v-for="attachment in attachments"
        :key="attachment.key"
        class="flex items-center gap-2 px-2 py-1 text-xs rounded-md bg-n-alpha-1"
      >
        <span
          class="flex-shrink-0 i-lucide-paperclip size-3.5 text-n-slate-11"
        />
        <a
          :href="attachment.url"
          target="_blank"
          rel="noopener noreferrer"
          class="truncate text-n-slate-12"
        >
          {{ attachment.name }}
        </a>
        <span v-if="attachment.size" class="flex-shrink-0 text-n-slate-10">
          {{ formatSize(attachment.size) }}
        </span>
        <button
          type="button"
          class="flex-shrink-0 ltr:ml-auto rtl:mr-auto text-n-slate-11 hover:text-n-ruby-9"
          :aria-label="$t('CANNED_MGMT.ATTACHMENTS.REMOVE')"
          @click="removeAttachment(attachment)"
        >
          <span class="i-lucide-x size-3.5" />
        </button>
      </li>
    </ul>
    <label
      class="flex items-center h-8 gap-2 px-2 py-1 text-xs border border-dashed rounded-lg cursor-pointer bg-n-background border-n-strong"
    >
      <input
        type="file"
        multiple
        accept="image/*,audio/*,video/*,.pdf"
        class="hidden"
        :disabled="isUploading"
        @change="onChangeFiles"
      />
      <Spinner v-if="isUploading" size="small" />
      <span v-else class="i-lucide-upload size-3.5" />
      <span>
        {{
          isUploading
            ? $t('CANNED_MGMT.ATTACHMENTS.UPLOADING')
            : $t('CANNED_MGMT.ATTACHMENTS.UPLOAD_BUTTON')
        }}
      </span>
    </label>
  </div>
</template>
