require "langchain"

class GeminiService
  def initialize
    @llm = Langchain::LLM::GoogleGemini.new(api_key: ENV["GEMINI_API_KEY"])
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

    response = @llm.chat(messages: [{ role: "user", content: prompt }])

    # Clean up response if it contains markdown code blocks
    clean_json = response.completion.gsub(/```json/, "").gsub(/```/, "").strip
    JSON.parse(clean_json)
  rescue JSON::ParserError => e
    Rails.logger.error("GeminiService JSON Error: #{e.message}")
    {}
  rescue => e
    Rails.logger.error("GeminiService Error: #{e.message}")
    {}
  end

  def generate_weekly_feedback(metrics_data, user_name)
    # metrics_data is expected to be an array of hashes or a summary string
    prompt = <<~PROMPT
      You are Rado, a high-performance fitness coach.
      Analyze the following weekly metrics for your client, #{user_name}.

      Metrics:
      #{metrics_data}

      Write a feedback paragraph (max 150 words).
      Tone: Motivational, strict, professional, direct.
      Highlight wins and call out missed targets.
    PROMPT

    response = @llm.chat(messages: [{ role: "user", content: prompt }])
    response.completion
  rescue => e
    Rails.logger.error("GeminiService Cleanup Error: #{e.message}")
    "Error generating feedback. Please try again."
  end
end
