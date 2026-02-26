require "rails_helper"

RSpec.describe ProcessMuxWebhookJob, type: :job do
  it "marks associated video asset ready" do
    book = create(:book)
    asset = create(:video_asset, :uploading, book: book, mux_upload_id: "upload_1")

    event = create(:webhook_event,
                   provider: "mux",
                   event_type: "video.asset.ready",
                   payload: {
                     "type" => "video.asset.ready",
                     "data" => {
                       "id" => "asset_1",
                       "upload_id" => "upload_1",
                       "duration" => 123.4,
                       "playback_ids" => [{ "id" => "playback_1", "policy" => "signed" }],
                     },
                   })

    described_class.perform_now(event.id)

    asset.reload
    expect(asset.processing_status).to eq("ready")
    expect(asset.mux_playback_id).to eq("playback_1")
    expect(event.reload.status).to eq("processed")
  end
end
