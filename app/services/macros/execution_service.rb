class Macros::ExecutionService < ActionService
  def initialize(macro, conversation, user)
    super(conversation)
    @macro = macro
    @account = macro.account
    @user = user
    Current.user = user
  end

  def perform
    @macro.actions.each_with_index do |action, index|
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
        report_interruption(action, index)
        break
      end
    end
  ensure
    Current.reset
  end

  private

  # A macro is an ordered script: later messages routinely refer to earlier ones, so skipping a
  # failed action leaves the contact with a sequence that no longer makes sense. Stop instead, and
  # leave a private note so the agent knows what is missing and can resend it.
  def report_interruption(action, index)
    content = I18n.t(
      'conversations.macros.execution_failed',
      macro_name: @macro.name,
      position: index + 1,
      total: @macro.actions.size,
      action_name: action[:action_name]
    )
    Messages::MessageBuilder.new(@user, @conversation.reload, { content: content, private: true }).perform
  rescue StandardError => e
    # The action that just failed was itself a message write, so this one can fail the same way.
    # Let the job finish instead of raising, otherwise the retry replays the whole sequence.
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
  end

  def assign_agent(agent_ids)
    agent_ids = agent_ids.map { |id| id == 'self' ? @user.id : id }
    super(agent_ids)
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true }

    # Added reload here to ensure conversation us persistent with the latest updates
    mb = Messages::MessageBuilder.new(@user, @conversation.reload, params)
    mb.perform
  end

  def send_message(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: false }

    # Added reload here to ensure conversation us persistent with the latest updates
    mb = Messages::MessageBuilder.new(@user, @conversation.reload, params)
    mb.perform
  end

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    return unless @macro.files.attached?

    blobs = ActiveStorage::Blob.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs }

    # Added reload here to ensure conversation us persistent with the latest updates
    mb = Messages::MessageBuilder.new(@user, @conversation.reload, params)
    mb.perform
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: 'macro.executed')
    WebhookJob.perform_later(webhook_url.first, payload)
  end
end
