class MediaConvertCreateJob < ApplicationJob
  queue_as :default

  def perform(video_asset_id)
    video_asset = VideoAsset.find(video_asset_id)

    video_asset.update!(processing_status: :processing, error_message: nil)
    job_id = MediaConvertService.new.create_hls_job(video_asset)

    video_asset.update!(
      mediaconvert_job_id: job_id,
      processing_status: :processing,
      hls_base_path: "books/#{video_asset.book_id}/hls/",
      hls_manifest_path: "books/#{video_asset.book_id}/hls/index.m3u8",
      error_message: nil,
    )
  rescue StandardError => e
    video_asset.update!(processing_status: :failed, error_message: e.message.truncate(500)) if video_asset&.persisted?
    raise
  end
end
