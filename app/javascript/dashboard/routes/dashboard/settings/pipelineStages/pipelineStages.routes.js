import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/pipeline-stages'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'pipeline_stages_wrapper',
          meta: {
            permissions: ['administrator'],
          },
          redirect: to => {
            return { name: 'pipeline_stages_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'pipeline_stages_list',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
