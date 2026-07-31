json.id scheduled_message.id
json.content scheduled_message.content
json.private scheduled_message.private
json.scheduled_at scheduled_message.scheduled_at.to_i
json.status scheduled_message.status
json.conversation_id scheduled_message.conversation_id
json.sender do
  json.id scheduled_message.sender.id
  json.name scheduled_message.sender.name
  json.avatar_url scheduled_message.sender.avatar_url
end
