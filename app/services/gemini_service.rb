require "net/http"
require "uri"
require "json"

class GeminiService
  def initialize
    @client = GeminiClient.new
  end

  def generate_weekly_feedback(name:, workouts:, diet_adherence:, weight:, week:)
    system_prompt = "Eres un coach de fitness de alto nivel, directo y exigente. Respondes en español."

    user_prompt = <<~PROMPT
      Escribe 2-3 oraciones de resumen semanal para el cliente.

      Datos de la semana:
      - Cliente: #{name}
      - Semana del programa: #{week}
      - Entrenamientos completados: #{workouts}
      - Adherencia a la dieta: #{diet_adherence}%
      - Peso actual: #{weight} kg

      El tono debe ser directo y motivador, sin condescendencia ni emojis. No incluyas saludo ni despedida. Solo el mensaje.
    PROMPT

    response = @client.call(system_prompt, user_prompt)
    response&.strip.presence || "Semana #{week} registrada. Seguí el proceso."
  rescue StandardError => e
    Rails.logger.error("GeminiService#generate_weekly_feedback Error: #{e.message}")
    "Semana #{week} registrada. Seguí el proceso."
  end

  def parse_metrics(text)
    system_prompt = "You are a specialized nutrition assistant. Parse user input into structured JSON."

    user_prompt = <<~PROMPT
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

    response = @client.call(system_prompt, user_prompt)
    @client.parse_json(response)
  rescue StandardError => e
    Rails.logger.error("GeminiService#parse_metrics Error: #{e.message}")
    {}
  end
end
