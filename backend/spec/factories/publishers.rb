FactoryBot.define do
  factory :publisher do
    sequence(:name) { |n| "Publisher #{n}" }
    billing_email { "billing@example.com" }
    contact_name { "Publisher Contact" }
    status { :active }
  end
end
