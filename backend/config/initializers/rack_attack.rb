class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  LOGIN_PATHS = [
    "/api/v1/auth/login",
    "/admin/login",
    "/publisher/login",
  ].freeze

  throttle("logins/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.post? && LOGIN_PATHS.include?(req.path)
  end

  throttle("logins/email", limit: 8, period: 10.minutes) do |req|
    next unless req.post? && LOGIN_PATHS.include?(req.path)

    req.params["email"].to_s.downcase.presence
  end

  throttle("exports/ip", limit: 20, period: 1.hour) do |req|
    next unless req.post?

    req.ip if req.path == "/publisher/exports" || req.path == "/admin/data_exports"
  end

  throttle("reports/ip", limit: 120, period: 1.minute) do |req|
    report_paths = [
      "/admin/api/v1/reports/usage",
      "/admin/api/v1/reports/analytics",
      "/publisher/analytics",
    ]

    req.ip if report_paths.include?(req.path)
  end

  self.throttled_responder = lambda do |request|
    body = {
      error: {
        code: "rate_limited",
        message: "Too many requests. Please try again later.",
      },
    }.to_json

    [429, { "Content-Type" => request.get_header("HTTP_ACCEPT").to_s.include?("json") ? "application/json" : "text/plain" }, [body]]
  end
end
