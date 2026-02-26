class PublisherStatement < ApplicationRecord
  enum :status, {
    draft: 0,
    approved: 1,
    paid: 2,
    failed: 3,
  }, default: :draft

  belongs_to :payout_period
  belongs_to :publisher

  validates :publisher_id, uniqueness: { scope: :payout_period_id }
  validates :gross_revenue_cents, :platform_fee_cents, :net_revenue_cents, :payout_amount_cents,
            numericality: { greater_than_or_equal_to: 0 }
  validates :rev_share_bps, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      breakdown calculated_at created_at gross_revenue_cents id minutes_watched net_revenue_cents payout_amount_cents
      payout_period_id platform_fee_cents play_ends play_starts publisher_id rev_share_bps status stripe_transfer_id
      unique_children updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[payout_period publisher]
  end
end
