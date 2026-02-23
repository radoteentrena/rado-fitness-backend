require "test_helper"
require "ostruct"

class GeminiServiceTest < ActiveSupport::TestCase
  class MockLLM
    attr_reader :calls

    def initialize(json_response: nil, text_response: nil)
      @json_response = json_response
      @text_response = text_response
      @calls = []
    end

    def chat(messages:)
      @calls << messages
      response_content = @json_response || @text_response
      OpenStruct.new(completion: response_content)
    end
  end

  setup do
    @service = GeminiService.new
  end

  test "parse_metrics returns valid JSON structure" do
    mock_json = '{"calories": 500, "protein": 40, "steps": 5000, "weight": 70.0}'
    mock_llm = MockLLM.new(json_response: mock_json)

    @service.instance_variable_set(:@llm, mock_llm)

    result = @service.parse_metrics("Some input")

    assert_equal 500, result["calories"]
    assert_equal 40, result["protein"]
    assert_equal 70.0, result["weight"]
    assert_equal 1, mock_llm.calls.length
  end

  test "generate_weekly_feedback returns a string" do
    mock_text = "Great job this week!"
    mock_llm = MockLLM.new(text_response: mock_text)

    @service.instance_variable_set(:@llm, mock_llm)

    result = @service.generate_weekly_feedback([ { calories: 2000 } ], "Diego")

    assert_equal "Great job this week!", result
    assert_equal 1, mock_llm.calls.length
  end
end
