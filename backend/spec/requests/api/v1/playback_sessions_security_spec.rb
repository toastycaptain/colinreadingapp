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

    it "returns mux playback URL and token when access is valid" do
      create(:library_item, child_profile: child, book: book, added_by_user: parent)
      create(:rights_window, book: book, publisher: publisher)
      create(:video_asset, :ready, book: book, mux_playback_id: "abc123")

      signer = instance_double(MuxSigning, token_for: "signed.jwt.token")
      allow(MuxSigning).to receive(:new).and_return(signer)

      post "/api/v1/children/#{child.id}/playback_sessions",
           params: { book_id: book.id }.to_json,
           headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(json["playback_hls_url"]).to eq("https://stream.mux.com/abc123.m3u8")
      expect(json["playback_token"]).to eq("signed.jwt.token")
      expect(json["expires_at"]).to be_present
    end
  end
end
