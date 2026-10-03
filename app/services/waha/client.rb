class Waha::Client
  def labels
    get('labels')
  end

  def create_label(name)
    request(:post, 'labels', body: { name: name, color: 0 }.to_json)
  end

  def chat_labels(chat_id)
    get("labels/chats/#{chat_id}")
  end

  def put_chat_labels(chat_id, label_ids)
    request(:put, "labels/chats/#{chat_id}", body: { labels: label_ids.map { |id| { id: id } } }.to_json)
  end

  def lid_for_phone(phone)
    get("lids/pn/#{phone}@c.us")['lid']
  end

  def phone_for_lid(lid)
    get("lids/#{lid}")['pn']
  end

  private

  def get(path)
    request(:get, path)
  end

  def request(method, path, body: nil)
    response = HTTParty.send(
      method,
      "#{ENV.fetch('WAHA_URL')}/api/#{ENV.fetch('WAHA_SESSION')}/#{path}",
      headers: { 'X-Api-Key' => ENV.fetch('WAHA_API_KEY'), 'Content-Type' => 'application/json' },
      body: body
    )
    raise "WAHA #{method.upcase} #{path} failed: #{response.code} #{response.body}" unless response.success?

    response.parsed_response
  end
end
