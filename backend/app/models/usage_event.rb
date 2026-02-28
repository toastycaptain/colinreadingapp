class UsageEvent < ApplicationRecord
  enum :event_type, {
    play_start: 0,
    pause: 1,
    resume: 2,
    play_end: 3,
    heartbeat: 4,
  }

  belongs_to :child_profile
  belongs_to :book
  belongs_to :playback_session, optional: true

  validates :event_type, :occurred_at, presence: true
  validates :watched_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :client_event_id, uniqueness: true, allow_nil: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      book_id child_profile_id client_event_id created_at event_type id metadata occurred_at playback_session_id
      position_seconds updated_at watched_seconds
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[book child_profile playback_session]
  end
end
