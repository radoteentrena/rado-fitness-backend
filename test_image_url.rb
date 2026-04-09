require 'net/http'
require 'uri'

url = URI("http://44.220.47.210/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MSwicHVyIjoiYmxvYl9pZCJ9fQ==--aaccbe446ea0dfef819524fe1f022e0b2186ba70/eyJfcmFpbHMiOnsiZGF0YSI6eyJmb3JtYXQiOiJwbmciLCJyZXNpemVfdG9fbGltaXQiOls4MDAsODAwXX0sInB1ciI6InZhcmlhdGlvbiJ9fQ==--ff3991cfe58cabdcdd5c75246ff1234921262cfe/Capture-2026-03-20-130654.png")

response = Net::HTTP.get_response(url)

puts "Response Status: #{response.code}"
puts "Response Headers: #{response.to_hash}"
if response.is_a?(Net::HTTPRedirection)
  redirect_url = URI(response['location'])
  puts "Redirecting to: #{redirect_url}"
  res2 = Net::HTTP.get_response(redirect_url)
  puts "Redirection Status: #{res2.code}"
  puts "Redirection Body Snippet: #{res2.body[0..200]}" if res2.code != '200'
else
  puts "Body snippet: #{response.body[0..200]}"
end
