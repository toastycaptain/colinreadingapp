require "rails_helper"

RSpec.describe "Auth API", type: :request do
  describe "POST /api/v1/auth/register" do
    it "creates a parent account and returns jwt" do
      post "/api/v1/auth/register", params: {
        email: "new-parent@example.com",
        password: "Password123!",
      }.to_json, headers: {
        "Content-Type" => "application/json",
        "ACCEPT" => "application/json",
      }

      expect(response).to have_http_status(:created)
      expect(json["jwt"]).to be_present
      expect(json.dig("user", "role")).to eq("parent")
    end
  end

  describe "POST /api/v1/auth/login" do
    it "returns unauthorized with invalid credentials" do
      create(:user, email: "login@example.com", password: "Password123!")

      post "/api/v1/auth/login", params: {
        email: "login@example.com",
        password: "WrongPassword!",
      }.to_json, headers: {
        "Content-Type" => "application/json",
        "ACCEPT" => "application/json",
      }

      expect(response).to have_http_status(:unauthorized)
      expect(json.dig("error", "code")).to eq("invalid_credentials")
    end
  end
end
