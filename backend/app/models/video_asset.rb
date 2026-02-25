class VideoAsset < ApplicationRecord
  enum :processing_status, { uploaded: 0, processing: 1, ready: 2, failed: 3 }, default: :uploaded

  belongs_to :book

  validates :master_s3_key, presence: true
  validates :mediaconvert_job_id, uniqueness: true, allow_nil: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[book_id created_at duration_seconds error_message hls_base_path hls_manifest_path id master_s3_key mediaconvert_job_id processing_status updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[book]
  end
end
