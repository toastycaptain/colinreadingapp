require "rails_helper"

RSpec.describe "Usage events API", type: :request do
  let(:parent) { create(:user, role: :parent) }
  let(:child) { create(:child_profile, user: parent) }
  let(:publisher) { create(:publisher) }
  let(:book) { create(:book, publisher: publisher) }

  before do
    create(:library_item, child_profile: child, book: book, added_by_user: parent)
  end

  describe "POST /api/v1/usage_events" do
    it "persists watched_seconds and playback_session_id" do
      playback_session = create(:playback_session, child_profile: child, book: book)

      post "/api/v1/usage_events",
           params: {
             child_id: child.id,
             book_id: book.id,
             playback_session_id: playback_session.id,
             event_type: "heartbeat",
             position_seconds: 30,
             watched_seconds: 12,
             client_event_id: SecureRandom.uuid,
             metadata: { source: "ios" },
           }.to_json,
           headers: auth_headers_for(parent)

      expect(response).to have_http_status(:created)
      expect(json["playback_session_id"]).to eq(playback_session.id)
      expect(json["watched_seconds"]).to eq(12)
      expect(json["client_event_id"]).to be_present
    end

    it "deduplicates on client_event_id" do
      event_id = SecureRandom.uuid

      payload = {
        child_id: child.id,
        book_id: book.id,
        event_type: "heartbeat",
        position_seconds: 60,
        client_event_id: event_id,
      }

      post "/api/v1/usage_events", params: payload.to_json, headers: auth_headers_for(parent)
      expect(response).to have_http_status(:created)
      first_id = json["id"]

      post "/api/v1/usage_events", params: payload.to_json, headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(first_id)
      expect(UsageEvent.where(client_event_id: event_id).count).to eq(1)
    end

    it "rejects playback sessions outside the child scope" do
      other_parent = create(:user, role: :parent)
      other_child = create(:child_profile, user: other_parent)
      foreign_session = create(:playback_session, child_profile: other_child, book: book)

      post "/api/v1/usage_events",
           params: {
             child_id: child.id,
             book_id: book.id,
             playback_session_id: foreign_session.id,
             event_type: "heartbeat",
           }.to_json,
           headers: auth_headers_for(parent)

      expect(response).to have_http_status(:not_found)
    end
  end
end
