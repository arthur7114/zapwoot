import { required } from '@vuelidate/validators';

export const getPipelineStageTitleErrorMessage = validation => {
  if (!validation.title.$error) return '';
  return 'PIPELINE_STAGE_MGMT.FORM.NAME.REQUIRED_ERROR';
};

export default {
  title: {
    required,
  },
  color: {},
};
