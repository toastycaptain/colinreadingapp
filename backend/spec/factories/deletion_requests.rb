FactoryBot.define do
  factory :deletion_request do
    association :user
    association :child_profile, factory: :child_profile
    status { :requested }
    reason { "Parent requested removal" }
    requested_at { Time.current }
    metadata { {} }
  end
end
