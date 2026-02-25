require "rails_helper"

RSpec.describe "Playback session security", type: :request do
  let(:parent) { create(:user, role: :parent) }
  let(:child) { create(:child_profile, user: parent) }
  let(:publisher) { create(:publisher) }
  let(:book) { create(:book, publisher: publisher) }

  describe "POST /api/v1/children/:child_id/playback_sessions" do
    it "denies playback when the book is not in the child library" do
      post "/api/v1/children/#{child.id}/playback_sessions",
           params: { book_id: book.id }.to_json,
           headers: auth_headers_for(parent)

      expect(response).to have_http_status(:forbidden)
      expect(json.dig("error", "code")).to eq("book_not_in_library")
    end

    it "denies playback when rights are expired" do
      create(:library_item, child_profile: child, book: book, added_by_user: parent)
      create(:rights_window, :expired, book: book, publisher: publisher)
      create(:video_asset, :ready, book: book)

      post "/api/v1/children/#{child.id}/playback_sessions",
           params: { book_id: book.id }.to_json,
           headers: auth_headers_for(parent)

      expect(response).to have_http_status(:forbidden)
      expect(json.dig("error", "code")).to eq("rights_expired")
    end
  end
end
