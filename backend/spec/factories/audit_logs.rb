FactoryBot.define do
  factory :audit_log do
    association :actor, factory: :admin_user
    action { "view_child_profile" }
    subject { nil }
    metadata { {} }
    occurred_at { Time.current }
  end
end
