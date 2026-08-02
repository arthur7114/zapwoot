require 'rails_helper'

RSpec.describe 'Canned Responses API', type: :request do
  let(:account) { create(:account) }

  before do
    create(:canned_response, account: account, content: 'Hey {{ contact.name }}, Thanks for reaching out', short_code: 'name-short-code')
  end

  describe 'GET /api/v1/accounts/{account.id}/canned_responses' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/canned_responses"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the canned responses' do
        get "/api/v1/accounts/#{account.id}/canned_responses",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expected = account.canned_responses.map { |cr| cr.as_json.merge('attachments' => []) }
        expect(response.parsed_body).to eq(expected)
      end

      it 'returns all the canned responses the user searched for' do
        cr1 = account.canned_responses.first
        create(:canned_response, account: account, content: 'Great! Looking forward', short_code: 'short-code')
        cr2 = create(:canned_response, account: account, content: 'Thanks for reaching out', short_code: 'content-with-thanks')
        cr3 = create(:canned_response, account: account, content: 'Thanks for reaching out', short_code: 'Thanks')

        params = { search: 'thanks' }

        get "/api/v1/accounts/#{account.id}/canned_responses",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expected = [cr3, cr2, cr1].map { |cr| cr.as_json.merge('attachments' => []) }
        expect(response.parsed_body).to eq(expected)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/canned_responses' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/canned_responses"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'creates a new canned response' do
        params = { short_code: 'short', content: 'content' }

        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(account.canned_responses.count).to eq(2)
      end

      it 'creates a canned response with an attachment' do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )

        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: { short_code: 'img', content: 'see image', blob_signed_ids: [blob.signed_id] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        canned_response = account.canned_responses.find_by(short_code: 'img')
        expect(canned_response.files.count).to eq(1)
        expect(response.parsed_body['attachments'].size).to eq(1)
        expect(response.parsed_body['attachments'].first['filename']).to eq('avatar.png')
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/canned_responses/:id' do
    let(:canned_response) { CannedResponse.last }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates an existing canned response' do
        params = { short_code: 'B' }

        put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(canned_response.reload.short_code).to eq('B')
      end

      it 'attaches and removes files on update' do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )
        canned_response.files.attach(blob)
        existing_attachment_id = canned_response.files.first.id

        new_blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/assets/sample.png').open,
          filename: 'sample.png',
          content_type: 'image/png'
        )

        put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
            params: {
              short_code: canned_response.short_code,
              blob_signed_ids: [new_blob.signed_id],
              deleted_attachment_ids: [existing_attachment_id]
            },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(canned_response.reload.files.map { |f| f.filename.to_s }).to contain_exactly('sample.png')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/canned_responses/:id' do
    let(:canned_response) { CannedResponse.last }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'destroys the canned response' do
        delete "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(CannedResponse.count).to eq(0)
      end
    end
  end
end
