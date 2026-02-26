class ProcessMuxWebhookJob < ApplicationJob
  queue_as :webhooks

  retry_on StandardError, wait: 5.seconds, attempts: 5

  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find(webhook_event_id)
    return if webhook_event.processed_at.present?

    webhook_event.with_lock do
      return if webhook_event.processed_at.present?

      process_payload(webhook_event.payload || {})
      webhook_event.update!(status: :processed, processed_at: Time.current)
    end
  rescue StandardError => e
    webhook_event&.update(status: :failed)
    AdminAlertMailer.with(subject: "Mux webhook processing failed", body: e.message).generic_alert.deliver_later
    raise
  end

  private

  def process_payload(payload)
    event_type = payload["type"].to_s
    data = payload["data"] || payload["object"] || {}

    case event_type
    when "video.upload.asset_created"
      process_upload_asset_created(data)
    when "video.asset.ready"
      process_asset_ready(data)
    when "video.asset.errored"
      process_asset_errored(data)
    end
  end

  def process_upload_asset_created(data)
    upload_id = data["id"] || data["upload_id"]
    asset_id = data["asset_id"] || data.dig("asset", "id")
    return if upload_id.blank? && asset_id.blank?

    video_asset = VideoAsset.find_by(mux_upload_id: upload_id) || VideoAsset.find_by(mux_asset_id: asset_id)
    return if video_asset.blank?

    video_asset.update!(
      mux_upload_id: upload_id.presence || video_asset.mux_upload_id,
      mux_asset_id: asset_id.presence || video_asset.mux_asset_id,
      processing_status: :processing,
      mux_error_message: nil,
    )
  end

  def process_asset_ready(data)
    asset_id = data["id"] || data["asset_id"]
    upload_id = data["upload_id"]
    return if asset_id.blank? && upload_id.blank?

    video_asset = VideoAsset.find_by(mux_asset_id: asset_id) || VideoAsset.find_by(mux_upload_id: upload_id)
    return if video_asset.blank?

    playback_ids = Array(data["playback_ids"])
    preferred_playback = playback_ids.find { |entry| entry["policy"] == "signed" } || playback_ids.first
    playback_id = preferred_playback&.dig("id")

    video_asset.update!(
      mux_asset_id: asset_id.presence || video_asset.mux_asset_id,
      mux_upload_id: upload_id.presence || video_asset.mux_upload_id,
      mux_playback_id: playback_id.presence || video_asset.mux_playback_id,
      duration_seconds: data["duration"]&.to_f&.round,
      processing_status: :ready,
      mux_error_message: nil,
    )
  end

  def process_asset_errored(data)
    asset_id = data["id"] || data["asset_id"]
    upload_id = data["upload_id"]
    return if asset_id.blank? && upload_id.blank?

    video_asset = VideoAsset.find_by(mux_asset_id: asset_id) || VideoAsset.find_by(mux_upload_id: upload_id)
    return if video_asset.blank?

    messages = Array(data.dig("errors", "messages")).compact
    message = messages.join(", ")
    message = data.dig("errors", "type") if message.blank?
    message = "Mux asset processing failed" if message.blank?

    video_asset.update!(
      mux_asset_id: asset_id.presence || video_asset.mux_asset_id,
      mux_upload_id: upload_id.presence || video_asset.mux_upload_id,
      processing_status: :failed,
      mux_error_message: message.truncate(500),
    )
  end
end
