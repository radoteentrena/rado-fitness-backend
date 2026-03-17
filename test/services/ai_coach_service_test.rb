require "test_helper"

class AiCoachServiceTest < ActiveSupport::TestCase
  def setup
    @service = AiCoachService.new
  end

  test "parses clean JSON correctly" do
    json_text = '{"program": {"name": "Test Program"}}'
    expected = { "program" => { "name" => "Test Program" } }

    assert_equal expected, @service.send(:parse_json_response, json_text)
  end

  test "parses JSON wrapped in markdown code fences" do
    valid_json = '{"program": {"name": "Test Program"}}'
    expected = { "program" => { "name" => "Test Program" } }
    markdown_json = "```json\n#{valid_json}\n```"

    assert_equal expected, @service.send(:parse_json_response, markdown_json)
  end

  test "parses JSON with extra whitespace and fences" do
    valid_json = '{"program": {"name": "Test Program"}}'
    expected = { "program" => { "name" => "Test Program" } }
    dirty_json = "   ```json   \n#{valid_json}\n   ```   "

    assert_equal expected, @service.send(:parse_json_response, dirty_json)
  end

  test "parses JSON from chatty response (conversational text)" do
    valid_json = '{"program": {"name": "Test Program"}}'
    expected = { "program" => { "name" => "Test Program" } }
    chatty_json = "Here is your program:\n```json\n#{valid_json}\n```\nLet me know if you need changes."

    assert_equal expected, @service.send(:parse_json_response, chatty_json)
  end

  test "parses JSON embedded in text without fences" do
    valid_json = '{"program": {"name": "Test Program"}}'
    expected = { "program" => { "name" => "Test Program" } }
    chatty_no_fence = "Here is the JSON: #{valid_json} Hope you like it."

    # This test might fail until we implement the robust parsing logic
    assert_equal expected, @service.send(:parse_json_response, chatty_no_fence)
  end

  test "returns empty hash for invalid JSON" do
    assert_equal({}, @service.send(:parse_json_response, "{ invalid_json }"))
  end

  test "returns empty hash for nil response" do
    assert_equal({}, @service.send(:parse_json_response, nil))
  end
end
