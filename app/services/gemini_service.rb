require "net/http"
require "uri"
require "json"

class GeminiService
  def initialize
    @api_key = ENV["GEMINI_API_KEY"]
    @base_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
  end

  def parse_metrics(text)
    prompt = <<~PROMPT
      You are a specialized nutrition assistant.
      Parse the following unstructured text into a valid JSON object with these keys:
      - calories (integer, estimate if needed)
      - protein (integer, grams)
      - steps (integer)
      - weight (float, kg)

      If a value is not mentioned, use null.
      Return ONLY the JSON.

      Input: "#{text}"
    PROMPT

    response_body = call_gemini(prompt)
    return {} unless response_body

    clean_json = response_body.gsub(/```json/, "").gsub(/```/, "").strip
    JSON.parse(clean_json)
  rescue JSON::ParserError => e
    Rails.logger.error("GeminiService JSON Error: #{e.message}")
    {}
  rescue => e
    Rails.logger.error("GeminiService Error: #{e.message}")
    {}
  end

  def generate_weekly_feedback(metrics_data, user_name)
    prompt = <<~PROMPT
      You are Rado, a high-performance fitness coach.
      Analyze the following weekly metrics for your client, #{user_name}.

      Metrics:
      #{metrics_data}

      Write a feedback paragraph (max 150 words).
      Tone: Motivational, strict, professional, direct.
      Highlight wins and call out missed targets.
    PROMPT

    call_gemini(prompt) || "Error generating feedback."
  end

  private

  def call_gemini(prompt)
    uri = URI("#{@base_url}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    if Rails.env.development?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      contents: [ { parts: [ { text: prompt } ] } ]
    }.to_json

    response = http.request(request)

    if response.code == "200"
      json = JSON.parse(response.body)
      json.dig("candidates", 0, "content", "parts", 0, "text")
    else
      Rails.logger.error("Gemini API Error: #{response.code} - #{response.body}")
      nil
    end
  end
end
