require "rails_helper"

RSpec.describe "Compliance API", type: :request do
  let(:parent) { create(:user, role: :parent) }

  describe "GET /api/v1/compliance/privacy_policy" do
    it "returns policy metadata" do
      get "/api/v1/compliance/privacy_policy", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(json["policy_version"]).to be_present
      expect(json["policy_url"]).to be_present
    end
  end

  describe "POST /api/v1/compliance/consents" do
    it "records parental consent" do
      post "/api/v1/compliance/consents", params: { policy_version: "2026-02" }.to_json, headers: auth_headers_for(parent)

      expect(response).to have_http_status(:created)
      expect(parent.parental_consents.count).to eq(1)
      expect(parent.reload.privacy_policy_version_accepted).to eq("2026-02")
    end
  end

  describe "POST /api/v1/compliance/deletion_requests" do
    it "creates deletion request and enqueues processing" do
      child = create(:child_profile, user: parent)

      expect {
        post "/api/v1/compliance/deletion_requests",
             params: { child_id: child.id, reason: "No longer needed" }.to_json,
             headers: auth_headers_for(parent)
      }.to have_enqueued_job(ProcessDeletionRequestJob)

      expect(response).to have_http_status(:created)
      expect(parent.deletion_requests.count).to eq(1)
      expect(json["status"]).to eq("requested")
    end
  end
end
