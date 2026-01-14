require_relative "config/environment"
require "ostruct"

puts "== Verifying GeminiService =="

# Mock the LLM
class MockLLM
  def chat(messages:)
    content = messages.first[:content]
    if content.include?("Parse the following")
      OpenStruct.new(completion: '{"calories": 500, "protein": 40, "steps": 10000, "weight": 75.5}')
    else
      OpenStruct.new(completion: "Feedback Generated Successfully")
    end
  end
end

service = GeminiService.new
service.instance_variable_set(:@llm, MockLLM.new)

puts "\n1. Testing Parse Metrics..."
metrics = service.parse_metrics("Ate 500 cals, 40g protein. Walked 10k steps. 75.5kg.")
puts "Result: #{metrics.inspect}"

unless metrics["calories"] == 500 && metrics["protein"] == 40 && metrics["steps"] == 10000 && metrics["weight"] == 75.5
  puts "❌ Parse Logic Failed"
  exit 1
end

puts "\n2. Testing Feedback..."
feedback = service.generate_weekly_feedback([], "TestUser")
puts "Result: #{feedback}"

unless feedback == "Feedback Generated Successfully"
  puts "❌ Feedback Logic Failed"
  exit 1
end

puts "\n✅ GeminiService Verified!"
