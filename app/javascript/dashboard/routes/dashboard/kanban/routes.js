import { frontendURL } from 'dashboard/helper/URLHelper';
import KanbanView from './KanbanView.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/kanban'),
    name: 'kanban_view',
    component: KanbanView,
    meta: {
      permissions: ['administrator', 'agent'],
    },
  },
];
