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

    ProcessMuxWebhookJob.perform_later(webhook_event.id)

    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue StandardError => e
    webhook_event&.update(status: :failed)
    Rails.logger.error("[MuxWebhook] receive error: #{e.class} #{e.message}")
    AdminAlertMailer.with(subject: "Mux webhook receive failed", body: e.message).generic_alert.deliver_later
    head :ok
  end
end
