require "net/http"
require "uri"
require "json"

class GeminiService
  def initialize
    @api_key = ENV["GEMINI_API_KEY"]
    @base_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"
  end

  def generate_weekly_feedback(name:, workouts:, diet_adherence:, weight:, week:)
    prompt = <<~PROMPT
      Eres un coach de fitness de alto nivel, directo y exigente. Escribe 2-3 oraciones en español para el resumen semanal del cliente.

      Datos de la semana:
      - Cliente: #{name}
      - Semana del programa: #{week}
      - Entrenamientos completados: #{workouts}
      - Adherencia a la dieta: #{diet_adherence}%
      - Peso actual: #{weight} kg

      El tono debe ser directo y motivador, sin condescendencia ni emojis. No incluyas saludo ni despedida. Solo el mensaje.
    PROMPT

    response = call_gemini(prompt)
    response&.strip.presence || "Semana #{week} registrada. Seguí el proceso."
  rescue => e
    Rails.logger.error("GeminiService#generate_weekly_feedback Error: #{e.message}")
    "Semana #{week} registrada. Seguí el proceso."
  end

  def parse_metrics(text)
    prompt = <<~PROMPT
      You are a specialized nutrition assistant.
      Parse the following unstructured text into a valid JSON object with these keys:
      - calories (integer, estimate if needed)
      - protein (integer, grams)
      - fats (integer, grams)
      - carbs (integer, grams)
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
