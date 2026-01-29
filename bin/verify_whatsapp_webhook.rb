require_relative "../config/environment"



puts "🔍 Verifying WhatsApp Webhook Integration..."

# 1. Provide Test Data
phone = "+15550009999"
# Ensure no cleanup collision
User.where(phone: phone).destroy_all
user = User.create!(
  first_name: "Test",
  last_name: "Webhook",
  email: "test_webhook@example.com",
  phone: phone,
  password: "password123"
)

puts "✅ Test User created: #{user.phone}"

# 2. Simulate Webhook Request
params = {
  "From" => "whatsapp:#{phone}",
  "Body" => "Test message: Ate 200g chicken",
  "AccountSid" => "AC123" # Mock SID
}

puts "📡 Sending POST request to /webhooks/whatsapp/incoming..."

# Use Rails Integration Test helper setup for standalone script
include Rails.application.routes.url_helpers
session = ActionDispatch::Integration::Session.new(Rails.application)
session.host = "127.0.0.1"
session.post "/webhooks/whatsapp/incoming", params: params

if session.response.code == "200"
  puts "✅ Response 200 OK"
else
  puts "❌ Response Failed: #{session.response.code}"
  puts session.response.body
  exit 1
end

# 3. Verify DailyMetric
metric = DailyMetric.where(user: user).last

if metric && metric.raw_message_content.include?("Ate 200g chicken")
  puts "✅ DailyMetric created successfully!"
  puts "   Content: #{metric.raw_message_content}"
  puts "   Date: #{metric.date_logged}"
  puts "   AI Parsed: #{metric.ai_parsed_json || 'Pending (Job/Service)'}"
else
  puts "❌ DailyMetric NOT found or content mismatch."
end

# Cleanup
user.destroy
puts "🧹 Cleanup complete."
