class Api::V1::Accounts::Conversations::ScheduledMessagesController < Api::V1::Accounts::Conversations::BaseController
  def index
    @scheduled_messages = @conversation.scheduled_messages.pending.order(scheduled_at: :asc)
  end

  def create
    @scheduled_message = @conversation.scheduled_messages.create!(
      scheduled_message_params.merge(account_id: @conversation.account_id, sender_id: Current.user.id)
    )
  end

  def destroy
    scheduled_message.canceled!
    head :ok
  end

  private

  def scheduled_message
    @scheduled_message ||= @conversation.scheduled_messages.pending.find(params[:id])
  end

  def scheduled_message_params
    params.permit(:content, :private, :scheduled_at)
  end
end
