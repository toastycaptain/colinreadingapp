FactoryBot.define do
  factory :data_export do
    association :requested_by, factory: :admin_user
    association :publisher
    export_type { :analytics_daily }
    params { { "start_date" => 7.days.ago.to_date.to_s, "end_date" => Date.current.to_s } }
    status { :pending }
  end
end
