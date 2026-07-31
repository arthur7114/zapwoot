<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import validations, { getPipelineStageTitleErrorMessage } from './validations';
import { getRandomColor } from 'dashboard/helper/labelColor';
import { useVuelidate } from '@vuelidate/core';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      title: '',
      color: '#000',
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'pipelineStages/getUIFlags',
      stages: 'pipelineStages/getPipelineStages',
    }),
    pipelineStageTitleErrorMessage() {
      return this.$t(getPipelineStageTitleErrorMessage(this.v$));
    },
  },
  mounted() {
    this.color = getRandomColor();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addPipelineStage() {
      try {
        await this.$store.dispatch('pipelineStages/create', {
          title: this.title,
          color: this.color,
          position: this.stages.length,
        });
        useAlert(this.$t('PIPELINE_STAGE_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        useAlert(
          error.message || this.$t('PIPELINE_STAGE_MGMT.ADD.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('PIPELINE_STAGE_MGMT.ADD.TITLE')"
      :header-content="$t('PIPELINE_STAGE_MGMT.ADD.DESC')"
    />
    <form class="flex flex-wrap mx-0" @submit.prevent="addPipelineStage">
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
          :label="$t('PIPELINE_STAGE_MGMT.FORM.CREATE')"
          :disabled="v$.title.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
        />
      </div>
    </form>
  </div>
</template>
