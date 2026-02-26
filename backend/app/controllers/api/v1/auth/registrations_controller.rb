class Api::V1::Auth::RegistrationsController < ApplicationController
  def create
    user = User.new(registration_params.merge(role: :parent))
    user.save!

    if params[:consent_accepted].to_s == "true"
      policy_version = params[:policy_version].presence || ENV.fetch("PRIVACY_POLICY_VERSION", "2026-02")
      consented_at = Time.current

      user.parental_consents.create!(
        policy_version: policy_version,
        consented_at: consented_at,
        metadata: {
          ip: request.remote_ip,
          user_agent: request.user_agent,
        },
      )

      user.update!(
        privacy_policy_version_accepted: policy_version,
        privacy_policy_accepted_at: consented_at,
      )
    end

    UserMailer.with(user: user).welcome_parent.deliver_later

    render json: {
      user: serialize_user(user),
      jwt: JwtTokenIssuer.call(user),
    }, status: :created
  end

  private

  def registration_params
    params.permit(:email, :password)
  end

  def serialize_user(user)
    user.as_json(only: %i[id email role created_at updated_at])
  end
end
