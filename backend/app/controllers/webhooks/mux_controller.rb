require "digest"
require "json"

class Webhooks::MuxController < ApplicationController
  skip_forgery_protection

  def receive
    raw_body = request.raw_post
    signature = request.headers["Mux-Signature"]

    unless MuxWebhookVerifier.new.valid?(signature_header: signature, raw_body: raw_body)
      return head :unauthorized
    end

    payload = JSON.parse(raw_body)
    event_id = payload["id"].presence || payload["event_id"].presence || Digest::SHA256.hexdigest(raw_body)

    webhook_event = WebhookEvent.find_or_initialize_by(provider: "mux", event_id: event_id)
    return head :ok if webhook_event.processed_at.present?

    webhook_event.assign_attributes(
      event_type: payload["type"].to_s,
      payload: payload,
      status: :received,
    )
    webhook_event.save!

    process_mux_event(payload)

    webhook_event.update!(status: :processed, processed_at: Time.current)
    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue StandardError => e
    webhook_event&.update(status: :failed)
    Rails.logger.error("[MuxWebhook] processing error: #{e.class} #{e.message}")
    head :ok
  end

  private

  def process_mux_event(payload)
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
