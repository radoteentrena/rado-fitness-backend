require "net/http"
require "uri"
require "json"

class EmbeddingService
  EMBEDDING_MODEL = "gemini-embedding-001"
  EMBEDDING_DIMENSIONS = 768

  def initialize
    @api_key = ENV["GEMINI_API_KEY"]
    @base_url = "https://generativelanguage.googleapis.com/v1beta/models/#{EMBEDDING_MODEL}:embedContent"
  end

  # Generate embedding for a single text string
  # Returns an array of floats (768 dimensions)
  def embed(text)
    if @api_key.blank?
      puts "\n❌ Error: GEMINI_API_KEY is not set in environment."
      return nil
    end

    uri = URI("#{@base_url}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      model: "models/#{EMBEDDING_MODEL}",
      content: { parts: [ { text: text } ] },
      outputDimensionality: EMBEDDING_DIMENSIONS
    }.to_json

    response = http.request(request)

    if response.code == "200"
      json = JSON.parse(response.body)
      json.dig("embedding", "values")
    else
      msg = "Embedding API Error: #{response.code} - #{response.body}"
      Rails.logger.error(msg)
      puts "\n⚠️ #{msg}" if defined?(Rake) || Rails.env.development?
      nil
    end
  rescue => e
    msg = "EmbeddingService Error: #{e.message}"
    Rails.logger.error(msg)
    puts "\n⚠️ #{msg}" if defined?(Rake) || Rails.env.development?
    nil
  end

  # Batch embed multiple texts (calls API sequentially to avoid rate limits)
  def embed_batch(texts)
    texts.map.with_index do |text, i|
      Rails.logger.info("Embedding chunk #{i + 1}/#{texts.size}...")
      result = embed(text)
      sleep(0.1) # Small delay to respect rate limits
      result
    end
  end
end
