<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import Draggable from 'vuedraggable';

import AddPipelineStage from './AddPipelineStage.vue';
import EditPipelineStage from './EditPipelineStage.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedStage = ref({});
const deletingId = ref(null);

const records = computed(
  () => getters['pipelineStages/getPipelineStages'].value
);
const uiFlags = computed(() => getters['pipelineStages/getUIFlags'].value);

const localStages = ref([...records.value]);
watch(records, newRecords => {
  localStages.value = [...newRecords];
});

const deleteMessage = computed(() => ` ${selectedStage.value.title}?`);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = stage => {
  showEditPopup.value = true;
  selectedStage.value = stage;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = stage => {
  showDeleteConfirmationPopup.value = true;
  selectedStage.value = stage;
};
const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteStage = async id => {
  try {
    await store.dispatch('pipelineStages/delete', id);
    useAlert(t('PIPELINE_STAGE_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error.message || t('PIPELINE_STAGE_MGMT.DELETE.API.ERROR_MESSAGE')
    );
  } finally {
    deletingId.value = null;
  }
};

const confirmDeletion = () => {
  deletingId.value = selectedStage.value.id;
  closeDeletePopup();
  deleteStage(selectedStage.value.id);
};

const onDragEnd = async () => {
  try {
    await store.dispatch(
      'pipelineStages/reorder',
      localStages.value.map(stage => stage.id)
    );
  } catch (error) {
    useAlert(t('PIPELINE_STAGE_MGMT.REORDER_ERROR'));
    localStages.value = [...records.value];
  }
};

onBeforeMount(() => {
  store.dispatch('pipelineStages/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('PIPELINE_STAGE_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('PIPELINE_STAGE_MGMT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('PIPELINE_STAGE_MGMT.HEADER')"
        :description="$t('PIPELINE_STAGE_MGMT.DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="$t('PIPELINE_STAGE_MGMT.HEADER_BTN_TXT')"
            size="sm"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <Draggable
        v-model="localStages"
        item-key="id"
        tag="ul"
        role="list"
        class="flex flex-col gap-2"
        handle=".drag-handle"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <li
            class="flex items-center gap-3 p-3 list-none border rounded-lg bg-n-solid-1 border-n-weak"
          >
            <span
              class="flex-shrink-0 cursor-grab drag-handle i-lucide-grip-vertical size-4 text-n-slate-9"
            />
            <span
              class="flex-shrink-0 rounded-full size-3"
              :style="{
                backgroundColor: element.color || 'var(--color-n-brand)',
              }"
            />
            <span class="text-body-main text-n-slate-12 grow">
              {{ element.title }}
            </span>
            <div class="flex flex-shrink-0 gap-2">
              <Button
                v-tooltip.top="$t('PIPELINE_STAGE_MGMT.FORM.EDIT')"
                icon="i-woot-edit-pen"
                slate
                sm
                @click="openEditPopup(element)"
              />
              <Button
                v-tooltip.top="$t('PIPELINE_STAGE_MGMT.FORM.DELETE')"
                icon="i-woot-bin"
                slate
                sm
                class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                :is-loading="deletingId === element.id"
                @click="openDeletePopup(element)"
              />
            </div>
          </li>
        </template>
      </Draggable>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddPipelineStage @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditPipelineStage
        :selected-stage="selectedStage"
        @close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('PIPELINE_STAGE_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('PIPELINE_STAGE_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('PIPELINE_STAGE_MGMT.DELETE.CONFIRM.YES')"
      :reject-text="$t('PIPELINE_STAGE_MGMT.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>
