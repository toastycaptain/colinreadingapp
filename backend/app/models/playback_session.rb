class PlaybackSession < ApplicationRecord
  belongs_to :child_profile
  belongs_to :book
  has_many :usage_events, dependent: :nullify

  validates :issued_at, :expires_at, presence: true
  validate :expires_after_issue

  def self.ransackable_attributes(_auth_object = nil)
    %w[book_id child_profile_id cloudfront_policy created_at expires_at id issued_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[book child_profile]
  end

  private

  def expires_after_issue
    return if issued_at.nil? || expires_at.nil? || expires_at > issued_at

    errors.add(:expires_at, "must be after issued_at")
  end
end
