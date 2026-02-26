class Api::V1::Compliance::ConsentsController < Api::V1::BaseController
  before_action :require_parent!

  def create
    consent = current_user.parental_consents.create!(
      policy_version: params[:policy_version].presence || ENV.fetch("PRIVACY_POLICY_VERSION", "2026-02"),
      consented_at: Time.current,
      metadata: {
        ip: request.remote_ip,
        user_agent: request.user_agent,
      },
    )

    current_user.update!(
      privacy_policy_version_accepted: consent.policy_version,
      privacy_policy_accepted_at: consent.consented_at,
    )

    UserMailer.with(user: current_user, policy_version: consent.policy_version).parental_consent_received.deliver_later

    render json: {
      id: consent.id,
      policy_version: consent.policy_version,
      consented_at: consent.consented_at,
    }, status: :created
  end
end
