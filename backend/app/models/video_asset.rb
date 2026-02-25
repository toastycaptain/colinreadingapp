class VideoAsset < ApplicationRecord
  enum :processing_status, { created: 0, uploading: 1, processing: 2, ready: 3, failed: 4 }, default: :created
  enum :playback_policy, { public: 0, signed: 1 }, default: :signed, prefix: :playback_policy

  belongs_to :book

  validates :mux_upload_id, presence: true, if: -> { uploading? || processing? }
  validates :mux_asset_id, :mux_playback_id, presence: true, if: :ready?

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      book_id created_at duration_seconds id mux_asset_id mux_error_message mux_playback_id mux_upload_id
      playback_policy processing_status updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[book]
  end
end
