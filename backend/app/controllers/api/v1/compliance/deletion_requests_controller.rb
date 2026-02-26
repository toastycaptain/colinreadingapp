class Api::V1::Compliance::DeletionRequestsController < Api::V1::BaseController
  before_action :require_parent!

  def index
    requests = current_user.deletion_requests.order(created_at: :desc).limit(50)

    render json: requests.as_json(
      only: [:id, :child_profile_id, :status, :reason, :requested_at, :processed_at, :created_at]
    )
  end

  def create
    child_profile = if params[:child_id].present?
      current_user.child_profiles.find(params[:child_id])
    end

    deletion_request = current_user.deletion_requests.create!(
      child_profile: child_profile,
      reason: params[:reason],
      requested_at: Time.current,
      status: :requested,
      metadata: {
        ip: request.remote_ip,
        user_agent: request.user_agent,
      },
    )

    ProcessDeletionRequestJob.perform_later(deletion_request.id)
    UserMailer.with(user: current_user, deletion_request: deletion_request).deletion_request_received.deliver_later
    AdminAlertMailer.with(subject: "New deletion request", body: "Deletion request ##{deletion_request.id} created").generic_alert.deliver_later

    render json: deletion_request.as_json(
      only: [:id, :child_profile_id, :status, :reason, :requested_at]
    ), status: :created
  end
end
