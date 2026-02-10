# verify_epic_3_integration.rb
require_relative 'config/environment'

puts "== Verifying Epic 3: AI Integration =="

# Ensure we have an API key
unless ENV["GEMINI_API_KEY"].present?
  puts "❌ GEMINI_API_KEY is missing from environment. Creating .env if needed..."
  # You might want to skip this check if you rely on Rails credentials, but CONTEXT.md says ENV.
end

puts "\n1. Testing GeminiService Connection..."
begin
  service = GeminiService.new
  test_input = "Weight 80kg, ate 2000 calories and 180g protein. 10000 steps."
  puts "   Input: '#{test_input}'"

  parsed = service.parse_metrics(test_input)
  puts "   Result: #{parsed.inspect}"

  if parsed["calories"].to_i == 2000 && parsed["protein"].to_i == 180
    puts "   ✅ GeminiService Parsing: SUCCESS"
  else
    puts "   ❌ GeminiService Parsing: FAILED (Check API or Prompt)"
  end
rescue => e
  puts "   ❌ Service Error: #{e.message}"
end

puts "\n2. Testing DailyMetric Callback..."
begin
  # Use an existing user or create a temporary one
  user = User.first || User.create!(email: "ai_test_#{Time.now.to_i}@example.com", password: "password", first_name: "AI", last_name: "Tester", category: :civil)

  metric = DailyMetric.new(
    user: user,
    date_logged: Date.today + 1.year, # Future date to avoid messing with real data
    raw_message_content: "Ate 2500 calories today, 200g protein, weight 81.5kg"
  )

  puts "   Saving metric with raw content..."
  if metric.save
    puts "   ✅ Metric Saved"
    puts "   Parsed JSON: #{metric.ai_parsed_json}"
    puts "   Attributes: Cal=#{metric.calories_consumed}, Prot=#{metric.protein_consumed}, W=#{metric.weight}"

    if metric.calories_consumed == 2500 && metric.protein_consumed == 200
      puts "   ✅ Callback Integration: SUCCESS"
      metric.destroy # Cleanup
    else
      puts "   ❌ Callback Integration: FAILED (Values mismatch)"
    end
  else
    puts "   ❌ Metric Save Failed: #{metric.errors.full_messages}"
  end
rescue => e
    puts "   ❌ Model Error: #{e.message}"
end

puts "\n3. Testing Feedback Generation..."
begin
  feedback = service.generate_weekly_feedback("Calories: 2000, Protein: 150g", "RadoTestUser")
  puts "   Feedback: #{feedback}"
  if feedback.is_a?(String) && feedback.length > 10 && !feedback.include?("Error")
    puts "   ✅ Feedback Generation: SUCCESS"
  else
    puts "   ❌ Feedback Generation: FAILED"
  end
rescue => e
  puts "   ❌ Feedback Error: #{e.message}"
end

puts "\n== Verification Complete =="
