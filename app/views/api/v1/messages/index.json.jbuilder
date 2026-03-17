json.array! @messages do |message|
  json.extract! message, :id, :content, :sender_type, :created_at
end
