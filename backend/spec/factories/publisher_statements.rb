FactoryBot.define do
  factory :publisher_statement do
    association :payout_period
    association :publisher
    status { :approved }
    minutes_watched { 120.5 }
    play_starts { 20 }
    play_ends { 18 }
    unique_children { 10 }
    gross_revenue_cents { 240 }
    platform_fee_cents { 36 }
    net_revenue_cents { 204 }
    rev_share_bps { 5000 }
    payout_amount_cents { 102 }
    breakdown { {} }
    calculated_at { Time.current }
  end
end
