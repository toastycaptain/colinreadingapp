class RightsWindow < ApplicationRecord
  belongs_to :publisher
  belongs_to :book

  validates :start_at, :end_at, :territory, presence: true
  validate :date_range_valid

  scope :active_at, ->(time = Time.current) {
    where("start_at <= ? AND end_at >= ?", time, time)
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[book_id created_at end_at id publisher_id start_at territory updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[book publisher]
  end

  private

  def date_range_valid
    return if start_at.nil? || end_at.nil? || start_at <= end_at

    errors.add(:end_at, "must be on or after start_at")
  end
end
