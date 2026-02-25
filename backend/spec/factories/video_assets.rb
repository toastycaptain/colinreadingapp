FactoryBot.define do
  factory :video_asset do
    association :book
    playback_policy { :signed }
    processing_status { :created }
    duration_seconds { 600 }

    trait :uploading do
      processing_status { :uploading }
      sequence(:mux_upload_id) { |n| "upload-#{n}" }
    end

    trait :ready do
      processing_status { :ready }
      sequence(:mux_asset_id) { |n| "asset-#{n}" }
      sequence(:mux_playback_id) { |n| "playback-#{n}" }
      sequence(:mux_upload_id) { |n| "upload-#{n}" }
    end

    trait :failed do
      processing_status { :failed }
      sequence(:mux_upload_id) { |n| "upload-#{n}" }
      mux_error_message { "Processing failed" }
    end
  end
end
