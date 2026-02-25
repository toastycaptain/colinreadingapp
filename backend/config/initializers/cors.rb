# Be sure to restart your server when you modify this file.

allowed_origins = ENV.fetch("CORS_ALLOWED_ORIGINS", "*")
origins = allowed_origins == "*" ? "*" : allowed_origins.split(",").map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins

    resource "*",
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             expose: ["Authorization"]
  end
end
