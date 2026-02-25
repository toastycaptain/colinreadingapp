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

  validates :event_type, :occurred_at, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[book_id child_profile_id created_at event_type id metadata occurred_at position_seconds updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[book child_profile]
  end
end
