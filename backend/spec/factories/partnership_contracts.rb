FactoryBot.define do
  factory :partnership_contract do
    association :publisher
    sequence(:contract_name) { |n| "Contract #{n}" }
    start_date { Date.current }
    end_date { 1.year.from_now.to_date }
    payment_model { :flat_fee }
    rev_share_bps { 1500 }
    minimum_guarantee_cents { 100_000 }
    notes { "Standard terms" }
    status { :active }
  end
end
