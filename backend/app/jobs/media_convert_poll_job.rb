class MediaConvertPollJob < ApplicationJob
  queue_as :default

  def perform(video_asset_id = nil)
    service = MediaConvertService.new

    scope = VideoAsset.processing.where.not(mediaconvert_job_id: nil)
    scope = scope.where(id: video_asset_id) if video_asset_id.present?

    scope.find_each do |video_asset|
      status = service.job_status(video_asset.mediaconvert_job_id)

      case status
      when "COMPLETE"
        video_asset.update!(
          processing_status: :ready,
          hls_base_path: "books/#{video_asset.book_id}/hls/",
          hls_manifest_path: "books/#{video_asset.book_id}/hls/index.m3u8",
          error_message: nil,
        )
      when "ERROR", "CANCELED"
        video_asset.update!(processing_status: :failed, error_message: "MediaConvert status: #{status}")
      end
    rescue StandardError => e
      video_asset.update!(processing_status: :failed, error_message: e.message.truncate(500))
    end
  end
end
