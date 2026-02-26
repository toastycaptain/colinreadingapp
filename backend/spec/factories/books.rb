FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Book #{n}" }
    author { "Author" }
    description { "Story book" }
    category { "Bedtime" }
    age_min { 3 }
    age_max { 8 }
    language { "en" }
    cover_image_url { "https://example.com/cover.png" }
    association :publisher
    status { :active }
  end
end
