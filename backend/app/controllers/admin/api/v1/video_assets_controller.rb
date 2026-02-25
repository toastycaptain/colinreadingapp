class Admin::Api::V1::VideoAssetsController < Admin::Api::V1::BaseController
  before_action :require_content_admin!
  before_action :set_video_asset, only: [:retry_processing, :poll_status]

  def create
    book = Book.find(params[:book_id])

    video_asset = book.video_asset || book.build_video_asset
    video_asset.assign_attributes(
      master_s3_key: params.require(:master_s3_key),
      hls_base_path: "books/#{book.id}/hls/",
      hls_manifest_path: "books/#{book.id}/hls/index.m3u8",
      processing_status: :uploaded,
      error_message: nil,
    )
    video_asset.save!

    MediaConvertCreateJob.perform_later(video_asset.id)

    render json: video_asset.as_json(only: %i[id book_id master_s3_key hls_base_path hls_manifest_path processing_status error_message]), status: :created
  end

  def retry_processing
    @video_asset.update!(processing_status: :uploaded, error_message: nil)
    MediaConvertCreateJob.perform_later(@video_asset.id)

    render json: { status: "enqueued", video_asset_id: @video_asset.id }
  end

  def poll_status
    MediaConvertPollJob.perform_now(@video_asset.id)
    @video_asset.reload

    render json: {
      id: @video_asset.id,
      processing_status: @video_asset.processing_status,
      error_message: @video_asset.error_message,
      hls_manifest_path: @video_asset.hls_manifest_path,
    }
  end

  private

  def set_video_asset
    @video_asset = VideoAsset.find(params[:id])
  end
end
