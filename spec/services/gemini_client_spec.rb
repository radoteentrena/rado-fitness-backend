require "rails_helper"

RSpec.describe GeminiClient do
  subject(:client) { described_class.new }

  describe "#parse_json" do
    let(:expected) { { "program" => { "name" => "Test Program" } } }
    let(:valid_json) { '{"program": {"name": "Test Program"}}' }

    it "parses clean JSON" do
      expect(client.parse_json(valid_json)).to eq(expected)
    end

    it "parses JSON wrapped in markdown code fences" do
      expect(client.parse_json("```json\n#{valid_json}\n```")).to eq(expected)
    end

    it "parses JSON with extra whitespace around the fences" do
      expect(client.parse_json("   ```json   \n#{valid_json}\n   ```   ")).to eq(expected)
    end

    it "parses JSON from a chatty fenced response" do
      chatty = "Here is your program:\n```json\n#{valid_json}\n```\nLet me know if you need changes."
      expect(client.parse_json(chatty)).to eq(expected)
    end

    it "parses JSON embedded in text without fences" do
      expect(client.parse_json("Here is the JSON: #{valid_json} Hope you like it.")).to eq(expected)
    end

    it "returns an empty hash for invalid JSON" do
      expect(client.parse_json("{ invalid_json }")).to eq({})
    end

    it "returns an empty hash for a nil response" do
      expect(client.parse_json(nil)).to eq({})
    end
  end
end
