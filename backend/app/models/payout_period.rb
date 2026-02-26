class PayoutPeriod < ApplicationRecord
  enum :status, {
    draft: 0,
    calculating: 1,
    ready: 2,
    paid: 3,
    failed: 4,
  }, default: :draft

  has_many :publisher_statements, dependent: :destroy

  validates :start_date, :end_date, :currency, presence: true
  validates :start_date, uniqueness: { scope: :end_date }
  validate :end_on_or_after_start

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      calculated_at created_at currency end_date id notes paid_at start_date status
      total_gross_revenue_cents total_payout_cents updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[publisher_statements]
  end

  private

  def end_on_or_after_start
    return if start_date.blank? || end_date.blank? || end_date >= start_date

    errors.add(:end_date, "must be on or after start_date")
  end
end
