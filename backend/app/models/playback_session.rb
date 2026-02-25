class PlaybackSession < ApplicationRecord
  belongs_to :child_profile
  belongs_to :book

  validates :issued_at, :expires_at, presence: true
  validate :expires_after_issue

  private

  def expires_after_issue
    return if issued_at.nil? || expires_at.nil? || expires_at > issued_at

    errors.add(:expires_at, "must be after issued_at")
  end
end
