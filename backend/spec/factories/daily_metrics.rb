FactoryBot.define do
  factory :daily_metric do
    metric_date { Date.current }
    association :publisher
    association :book
    play_starts { 5 }
    play_ends { 4 }
    unique_children { 3 }
    minutes_watched { 20.5 }
    avg_completion_rate { 0.72 }
  end
end
