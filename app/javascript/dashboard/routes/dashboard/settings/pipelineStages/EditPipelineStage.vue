<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import validations, { getPipelineStageTitleErrorMessage } from './validations';
import { useVuelidate } from '@vuelidate/core';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    selectedStage: {
      type: Object,
      default: () => {},
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      title: '',
      color: '',
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'pipelineStages/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('PIPELINE_STAGE_MGMT.EDIT.TITLE')} - ${
        this.selectedStage.title
      }`;
    },
    pipelineStageTitleErrorMessage() {
      return this.$t(getPipelineStageTitleErrorMessage(this.v$));
    },
  },
  mounted() {
    this.title = this.selectedStage.title;
    this.color = this.selectedStage.color;
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    editPipelineStage() {
      this.$store
        .dispatch('pipelineStages/update', {
          id: this.selectedStage.id,
          title: this.title,
          color: this.color,
        })
        .then(() => {
          useAlert(this.$t('PIPELINE_STAGE_MGMT.EDIT.API.SUCCESS_MESSAGE'));
          setTimeout(() => this.onClose(), 10);
        })
        .catch(() => {
          useAlert(this.$t('PIPELINE_STAGE_MGMT.EDIT.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="pageTitle" />
    <form class="flex flex-wrap mx-0" @submit.prevent="editPipelineStage">
      <woot-input
        v-model="title"
        :class="{ error: v$.title.$error }"
        class="w-full"
        :label="$t('PIPELINE_STAGE_MGMT.FORM.NAME.LABEL')"
        :placeholder="$t('PIPELINE_STAGE_MGMT.FORM.NAME.PLACEHOLDER')"
        :error="pipelineStageTitleErrorMessage"
        @input="v$.title.$touch"
        @blur="v$.title.$touch"
      />
      <div class="w-full">
        <label>
          {{ $t('PIPELINE_STAGE_MGMT.FORM.COLOR.LABEL') }}
          <woot-color-picker v-model="color" />
        </label>
      </div>
      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('PIPELINE_STAGE_MGMT.FORM.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :label="$t('PIPELINE_STAGE_MGMT.FORM.EDIT')"
          :disabled="v$.title.$invalid || uiFlags.isUpdating"
          :is-loading="uiFlags.isUpdating"
        />
      </div>
    </form>
  </div>
</template>
