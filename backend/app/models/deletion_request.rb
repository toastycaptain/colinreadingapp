class DeletionRequest < ApplicationRecord
  enum :status, {
    requested: "requested",
    processing: "processing",
    completed: "completed",
    failed: "failed",
  }, default: :requested, validate: true

  belongs_to :user
  belongs_to :child_profile, optional: true

  validates :requested_at, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[child_profile_id created_at id metadata processed_at reason requested_at status updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[child_profile user]
  end
end
