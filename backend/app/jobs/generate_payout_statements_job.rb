class GeneratePayoutStatementsJob < ApplicationJob
  queue_as :payouts

  def perform(payout_period_id)
    payout_period = PayoutPeriod.find(payout_period_id)

    payout_period.update!(status: :calculating, notes: nil)

    calculations = RoyaltyCalculator.new(payout_period: payout_period).call

    ActiveRecord::Base.transaction do
      payout_period.publisher_statements.delete_all

      calculations.each do |row|
        payout_period.publisher_statements.create!(
          publisher: row.fetch(:publisher),
          status: :approved,
          minutes_watched: row.fetch(:minutes_watched),
          play_starts: row.fetch(:play_starts),
          play_ends: row.fetch(:play_ends),
          unique_children: row.fetch(:unique_children),
          gross_revenue_cents: row.fetch(:gross_revenue_cents),
          platform_fee_cents: row.fetch(:platform_fee_cents),
          net_revenue_cents: row.fetch(:net_revenue_cents),
          rev_share_bps: row.fetch(:rev_share_bps),
          payout_amount_cents: row.fetch(:payout_amount_cents),
          breakdown: row.fetch(:breakdown),
          calculated_at: Time.current,
        )
      end

      payout_period.update!(
        status: :ready,
        calculated_at: Time.current,
        total_gross_revenue_cents: payout_period.publisher_statements.sum(:gross_revenue_cents),
        total_payout_cents: payout_period.publisher_statements.sum(:payout_amount_cents),
      )
    end
  rescue StandardError => e
    payout_period&.update(status: :failed, notes: e.message.truncate(500))
    AdminAlertMailer.with(subject: "Payout job failed", body: e.message).generic_alert.deliver_later
    raise
  end
end
