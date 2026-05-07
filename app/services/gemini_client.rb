require "net/http"
require "uri"
require "json"

class GeminiClient
  MODEL = "gemini-flash-latest"

  def initialize(api_key: ENV["GEMINI_API_KEY"], model: MODEL)
    @api_key = api_key
    @model   = model
    @base_url = "https://generativelanguage.googleapis.com/v1beta/models/#{@model}:generateContent"
  end

  def call(system_prompt, user_prompt, history: [])
    uri  = URI("#{@base_url}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    contents = history.map do |msg|
      { role: msg[:role] == "assistant" ? "model" : "user",
        parts: [ { text: msg[:content] } ] }
    end
    contents << { role: "user", parts: [ { text: user_prompt } ] }

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      system_instruction: { parts: [ { text: system_prompt } ] },
      contents: contents,
      generationConfig: { temperature: 0.7, maxOutputTokens: 8192 }
    }.to_json

    perform(http, request)
  end

  def parse_json(text)
    return {} unless text

    begin
      return JSON.parse(text)
    rescue JSON::ParserError
    end

    if (match = text.match(/```json\s*(.*?)\s*```/m))
      begin return JSON.parse(match[1]) rescue JSON::ParserError; end
    end

    if (match = text.match(/```\s*(.*?)\s*```/m))
      begin return JSON.parse(match[1]) rescue JSON::ParserError; end
    end

    first_brace = text.index("{")
    last_brace  = text.rindex("}")
    if first_brace && last_brace && last_brace > first_brace
      begin
        return JSON.parse(text[first_brace..last_brace])
      rescue JSON::ParserError => e
        Rails.logger.error("GeminiClient JSON extract failed: #{e.message}")
      end
    end

    Rails.logger.error("GeminiClient failed to parse response: #{text.first(100)}...")
    {}
  rescue JSON::ParserError => e
    Rails.logger.error("GeminiClient JSON parse error: #{e.message}")
    {}
  end

  private

  def perform(http, request, attempt: 1)
    response = http.request(request)

    case response.code
    when "200"
      json = JSON.parse(response.body)
      json.dig("candidates", 0, "content", "parts", 0, "text")
    when "429"
      if attempt <= 3
        wait = 2 ** attempt
        Rails.logger.warn("Gemini 429 – retrying in #{wait}s (attempt #{attempt}/3)")
        sleep(wait)
        perform(http, request, attempt: attempt + 1)
      else
        raise "Gemini API rate limit exceeded after 3 retries"
      end
    else
      Rails.logger.error("Gemini API Error: #{response.code} - #{response.body}")
      raise "Gemini API error: #{response.code}"
    end
  end
end
