module AuthHelper
  def auth_headers_for(user)
    token = JwtTokenIssuer.call(user)

    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json",
      "ACCEPT" => "application/json",
    }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end
