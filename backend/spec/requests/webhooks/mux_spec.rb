require "rails_helper"

RSpec.describe "Mux webhooks", type: :request do
  it "marks a video asset ready when receiving video.asset.ready" do
    book = create(:book)
    video_asset = create(:video_asset, :uploading, book: book, mux_upload_id: "upload_123")

    payload = {
      id: "evt_1",
      type: "video.asset.ready",
      data: {
        id: "asset_123",
        upload_id: "upload_123",
        duration: 120.4,
        playback_ids: [
          { id: "playback_public", policy: "public" },
          { id: "playback_signed", policy: "signed" },
        ],
      },
    }

    allow_any_instance_of(MuxWebhookVerifier).to receive(:valid?).and_return(true)

    expect {
      post "/webhooks/mux", params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json", "Mux-Signature" => "test" }
    }.to have_enqueued_job(ProcessMuxWebhookJob)

    expect(response).to have_http_status(:ok)

    perform_enqueued_jobs

    video_asset.reload
    expect(video_asset.processing_status).to eq("ready")
    expect(video_asset.mux_asset_id).to eq("asset_123")
    expect(video_asset.mux_playback_id).to eq("playback_signed")
    expect(video_asset.duration_seconds).to eq(120)

    event = WebhookEvent.find_by(provider: "mux", event_id: "evt_1")
    expect(event).to be_present
    expect(event.status).to eq("processed")
  end

  it "returns unauthorized for invalid signatures" do
    allow_any_instance_of(MuxWebhookVerifier).to receive(:valid?).and_return(false)

    expect {
      post "/webhooks/mux", params: { type: "video.asset.ready" }.to_json,
                             headers: { "CONTENT_TYPE" => "application/json", "Mux-Signature" => "bad" }
    }.not_to have_enqueued_job(ProcessMuxWebhookJob)

    expect(response).to have_http_status(:unauthorized)
  end
end
