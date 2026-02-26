class PartnershipContract < ApplicationRecord
  enum :payment_model, { flat_fee: 0, rev_share: 1, hybrid: 2 }, default: :flat_fee
  enum :status, { draft: 0, active: 1, expired: 2, terminated: 3 }, default: :draft

  belongs_to :publisher

  validates :contract_name, :start_date, :end_date, presence: true
  validates :rev_share_bps, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }
  validate :date_range_valid
  validate :rev_share_required_for_revenue_models

  scope :active_on, ->(date) {
    where("start_date <= ? AND end_date >= ?", date, date)
      .where(status: statuses[:active])
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[contract_name created_at end_date id minimum_guarantee_cents notes payment_model publisher_id rev_share_bps start_date status updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[publisher]
  end

  private

  def date_range_valid
    return if start_date.nil? || end_date.nil? || start_date <= end_date

    errors.add(:end_date, "must be on or after start_date")
  end

  def rev_share_required_for_revenue_models
    return unless rev_share? || hybrid?
    return if rev_share_bps.to_i.positive?

    errors.add(:rev_share_bps, "must be present when payment model includes revenue share")
  end
end
