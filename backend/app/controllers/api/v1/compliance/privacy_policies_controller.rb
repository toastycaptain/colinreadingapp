class Api::V1::Compliance::PrivacyPoliciesController < Api::V1::BaseController
  before_action :require_parent!

  def show
    render json: {
      policy_version: policy_version,
      policy_url: policy_url,
      terms_url: terms_url,
      retention_days: retention_days,
      child_data_deletion_contact: ENV.fetch("CHILD_DATA_DELETION_CONTACT", "privacy@example.com"),
    }
  end

  private

  def policy_version
    ENV.fetch("PRIVACY_POLICY_VERSION", "2026-02")
  end

  def policy_url
    ENV.fetch("PRIVACY_POLICY_URL", "https://www.example.com/privacy")
  end

  def terms_url
    ENV.fetch("TERMS_OF_SERVICE_URL", "https://www.example.com/terms")
  end

  def retention_days
    ENV.fetch("DATA_RETENTION_DAYS", "365").to_i
  end
end
