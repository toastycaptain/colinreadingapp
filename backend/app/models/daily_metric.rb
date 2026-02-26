class DailyMetric < ApplicationRecord
  belongs_to :publisher, optional: true
  belongs_to :book, optional: true

  validates :metric_date, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[avg_completion_rate book_id created_at id metric_date minutes_watched play_ends play_starts publisher_id unique_children updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[book publisher]
  end
end
