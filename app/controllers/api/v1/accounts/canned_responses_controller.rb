class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    render json: serialize(canned_responses)
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params)
    @canned_response.save!
    attach_files(attachment_params[:blob_signed_ids])
    render json: serialize(@canned_response)
  end

  def update
    @canned_response.update!(canned_response_params)
    attach_files(attachment_params[:blob_signed_ids])
    purge_files(attachment_params[:deleted_attachment_ids])
    render json: serialize(@canned_response)
  end

  def destroy
    @canned_response.destroy!
    head :ok
  end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def canned_response_params
    params.require(:canned_response).permit(:short_code, :content)
  end

  def attachment_params
    # Read at top level (like macros): ParamsWrapper only mirrors model
    # attributes into :canned_response, so these arrays stay at the root.
    params.permit(blob_signed_ids: [], deleted_attachment_ids: [])
  end

  def attach_files(signed_ids)
    Array(signed_ids).each do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id)
      @canned_response.files.attach(blob) if blob
    end
  end

  def purge_files(attachment_ids)
    return if attachment_ids.blank?

    # purge_later keeps blobs still referenced by sent messages intact.
    @canned_response.files.where(id: attachment_ids).find_each(&:purge_later)
  end

  def canned_responses
    scope = if params[:search]
              Current.account.canned_responses
                     .where('short_code ILIKE :search OR content ILIKE :search', search: "%#{params[:search]}%")
                     .order_by_search(params[:search])
            else
              Current.account.canned_responses
            end
    scope.with_attached_files
  end

  def serialize(records)
    return serialize_canned_response(records) unless records.respond_to?(:map)

    records.map { |canned_response| serialize_canned_response(canned_response) }
  end

  def serialize_canned_response(canned_response)
    canned_response.as_json.merge(attachments: canned_response.file_base_data)
  end
end
