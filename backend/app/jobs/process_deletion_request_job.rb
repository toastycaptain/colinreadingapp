class ProcessDeletionRequestJob < ApplicationJob
  queue_as :compliance

  def perform(deletion_request_id)
    deletion_request = DeletionRequest.find(deletion_request_id)

    deletion_request.update!(status: :processing)

    ActiveRecord::Base.transaction do
      if deletion_request.child_profile.present?
        deletion_request.child_profile.destroy!
      else
        user = deletion_request.user
        user.child_profiles.destroy_all
        user.library_items.destroy_all

        anonymized_email = "deleted-user-#{user.id}-#{SecureRandom.hex(4)}@example.invalid"
        user.update!(
          email: anonymized_email,
          encrypted_password: User.new(password: SecureRandom.hex(24)).encrypted_password,
          jti: SecureRandom.uuid,
        )
      end

      deletion_request.update!(
        status: :completed,
        processed_at: Time.current,
      )
    end
  rescue StandardError => e
    deletion_request&.update(status: :failed, metadata: (deletion_request.metadata || {}).merge(error: e.message))
    AdminAlertMailer.with(subject: "Deletion request failed", body: e.message).generic_alert.deliver_later
    raise
  end
end
