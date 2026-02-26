FactoryBot.define do
  factory :payout_period do
    start_date { Date.current.beginning_of_month }
    end_date { Date.current.end_of_month }
    currency { "USD" }
    status { :draft }
  end
end
