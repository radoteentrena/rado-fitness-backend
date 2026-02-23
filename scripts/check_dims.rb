require "net/http"
require "uri"
require "json"

api_key = ENV["GEMINI_API_KEY"]
model = "gemini-embedding-001"
version = "v1beta"

uri = URI("https://generativelanguage.googleapis.com/#{version}/models/#{model}:embedContent?key=#{api_key}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri)
request["Content-Type"] = "application/json"
request.body = {
  model: "models/#{model}",
  content: { parts: [ { text: "Dimensions test" } ] }
}.to_json

response = http.request(request)
if response.code == "200"
  values = JSON.parse(response.body).dig("embedding", "values")
  puts "✅ Model: #{model}"
  puts "✅ Dimensions returned: #{values.size}"
else
  puts "❌ Error: #{response.body}"
end
