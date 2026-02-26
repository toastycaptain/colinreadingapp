require "rails_helper"

RSpec.describe GeneratePayoutStatementsJob, type: :job do
  it "creates statements and marks payout period as ready" do
    payout_period = create(:payout_period)

    calculation = {
      publisher: create(:publisher),
      minutes_watched: 60.0,
      play_starts: 5,
      play_ends: 4,
      unique_children: 3,
      gross_revenue_cents: 120,
      platform_fee_cents: 12,
      net_revenue_cents: 108,
      rev_share_bps: 5000,
      payout_amount_cents: 54,
      breakdown: [],
    }

    calculator = instance_double(RoyaltyCalculator, call: [calculation])
    allow(RoyaltyCalculator).to receive(:new).and_return(calculator)

    described_class.perform_now(payout_period.id)

    payout_period.reload
    expect(payout_period.status).to eq("ready")
    expect(payout_period.publisher_statements.count).to eq(1)
    expect(payout_period.total_payout_cents).to eq(54)
  end
end
