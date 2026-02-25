FactoryBot.define do
  factory :video_asset do
    association :book
    sequence(:master_s3_key) { |n| "uploads/master-#{n}.mp4" }
    hls_base_path { "books/#{book.id}/hls/" }
    hls_manifest_path { "books/#{book.id}/hls/index.m3u8" }
    duration_seconds { 600 }
    processing_status { :uploaded }

    trait :ready do
      processing_status { :ready }
      mediaconvert_job_id { "job-123" }
    end
  end
end
