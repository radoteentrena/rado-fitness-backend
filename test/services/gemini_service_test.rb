require "test_helper"
require "ostruct"

class GeminiServiceTest < ActiveSupport::TestCase
  setup do
    @service = GeminiService.new
  end

  test "parse_metrics returns valid JSON structure" do
    mock_json = '{"calories": 500, "protein": 40, "steps": 5000, "weight": 70.0}'

    @service.stub(:call_gemini, mock_json) do
      result = @service.parse_metrics("Some input")

      assert_equal 500, result["calories"]
      assert_equal 40, result["protein"]
      assert_equal 70.0, result["weight"]
    end
  end

  test "generate_weekly_feedback returns a string" do
    mock_text = "Great job this week!"

    @service.stub(:call_gemini, mock_text) do
      result = @service.generate_weekly_feedback([ { calories: 2000 } ], "Diego")

      assert_equal "Great job this week!", result
    end
  end
end
