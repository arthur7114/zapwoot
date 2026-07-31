/* global axios */
import ApiClient from '../ApiClient';

class ScheduledMessageApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  get(conversationId) {
    return axios.get(`${this.url}/${conversationId}/scheduled_messages`);
  }

  create({ conversationId, content, isPrivate, scheduledAt }) {
    return axios.post(`${this.url}/${conversationId}/scheduled_messages`, {
      content,
      private: isPrivate,
      scheduled_at: scheduledAt,
    });
  }

  cancel(conversationId, scheduledMessageId) {
    return axios.delete(
      `${this.url}/${conversationId}/scheduled_messages/${scheduledMessageId}`
    );
  }
}

export default new ScheduledMessageApi();
