class Admin::Api::V1::MuxController < Admin::Api::V1::BaseController
  before_action :require_content_admin!

  def direct_upload
    book = Book.find(params.require(:book_id))

    upload = MuxClient.new.create_direct_upload(
      playback_policy: :signed,
      passthrough: "book:#{book.id}",
    )

    video_asset = book.video_asset || book.build_video_asset
    video_asset.update!(
      mux_upload_id: upload.id,
      mux_asset_id: nil,
      mux_playback_id: nil,
      playback_policy: :signed,
      processing_status: :uploading,
      mux_error_message: nil,
    )

    render json: {
      upload_id: upload.id,
      upload_url: upload.url,
      video_asset_id: video_asset.id,
    }, status: :created
  end
end
