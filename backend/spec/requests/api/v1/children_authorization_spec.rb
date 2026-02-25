require "rails_helper"

RSpec.describe "Children library authorization", type: :request do
  describe "GET /api/v1/children/:child_id/library" do
    it "does not allow a parent to access another parent's child" do
      parent = create(:user, role: :parent)
      other_parent = create(:user, role: :parent)
      other_child = create(:child_profile, user: other_parent)

      get "/api/v1/children/#{other_child.id}/library", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:not_found)
      expect(json.dig("error", "code")).to eq("not_found")
    end
  end
end
