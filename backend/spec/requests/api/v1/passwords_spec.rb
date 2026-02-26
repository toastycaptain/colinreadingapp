require "rails_helper"

RSpec.describe "Password API", type: :request do
  describe "POST /api/v1/auth/password/forgot" do
    it "returns ok even when email is unknown" do
      post "/api/v1/auth/password/forgot", params: { email: "missing@example.com" }.to_json, headers: {
        "Content-Type" => "application/json",
        "ACCEPT" => "application/json",
      }

      expect(response).to have_http_status(:ok)
    end

    it "returns ok for existing users" do
      user = create(:user, email: "parent@example.com")

      post "/api/v1/auth/password/forgot", params: { email: user.email }.to_json, headers: {
        "Content-Type" => "application/json",
        "ACCEPT" => "application/json",
      }

      expect(response).to have_http_status(:ok)
    end
  end
end
