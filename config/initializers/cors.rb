Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://radoteentrena.com", "https://www.radoteentrena.com"

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "Authorization" ]
  end
end
