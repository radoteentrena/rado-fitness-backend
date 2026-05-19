Rack::Attack.cache.store = Rails.cache

# Throttle auth attempts by IP: 5 per minute
Rack::Attack.throttle("auth/ip", limit: 5, period: 1.minute) do |request|
  if request.path.start_with?("/api/v1/auth/") && request.post?
    request.ip
  end
end

# Throttle auth attempts by email param: 10 per hour (catches credential stuffing)
Rack::Attack.throttle("auth/email", limit: 10, period: 1.hour) do |request|
  if request.path == "/api/v1/auth/email" && request.post?
    request.params["email"].to_s.downcase.strip.presence
  end
end

# Throttle onboarding form submissions by IP: 10 per hour
Rack::Attack.throttle("onboarding/ip", limit: 10, period: 1.hour) do |request|
  if request.path == "/onboarding" && request.post?
    request.ip
  end
end

Rack::Attack.throttled_responder = lambda do |env|
  [
    429,
    { "Content-Type" => "application/json" },
    [ { error: "Too many requests. Please try again later." }.to_json ]
  ]
end
