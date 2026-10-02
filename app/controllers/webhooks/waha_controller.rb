class Webhooks::WahaController < ActionController::API
  LABEL_EVENTS = %w[label.chat.added label.chat.deleted].freeze

  def process_payload
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(request.headers['X-Api-Key'].to_s, ENV.fetch('WAHA_API_KEY'))

    if LABEL_EVENTS.include?(params[:event]) && params[:session] == ENV.fetch('WAHA_SESSION')
      Waha::LabelEventJob.perform_later(params[:event], params[:payload].to_unsafe_h)
    end
    head :ok
  end
end
