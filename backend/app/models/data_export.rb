class DataExport < ApplicationRecord
  attr_accessor :start_date, :end_date, :book_id, :child_profile_id

  enum :export_type, {
    usage_daily: 0,
    analytics_daily: 1,
    statement_breakdown: 2,
  }, default: :analytics_daily

  enum :status, {
    pending: 0,
    processing: 1,
    ready: 2,
    failed: 3,
  }, default: :pending

  belongs_to :requested_by, polymorphic: true
  belongs_to :publisher, optional: true

  validates :export_type, :status, presence: true
  validates :publisher_id, presence: true, if: -> { requested_by_type == "PublisherUser" }

  def file_path
    return nil if file_url.blank?

    Pathname.new(file_url)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      created_at error_message export_type file_url generated_at id params publisher_id requested_by_id requested_by_type
      status updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[publisher]
  end
end
