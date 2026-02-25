class Book < ApplicationRecord
  enum :status, { draft: 0, active: 1, inactive: 2 }, default: :draft

  belongs_to :publisher, optional: true

  has_one :video_asset, dependent: :destroy
  has_many :library_items, dependent: :destroy
  has_many :rights_windows, dependent: :destroy
  has_many :child_profiles, through: :library_items
  has_many :playback_sessions, dependent: :destroy
  has_many :usage_events, dependent: :destroy

  validates :title, :author, :language, presence: true
  validates :age_min, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :age_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :age_range_valid

  scope :search, ->(query) {
    return all if query.blank?

    where("title ILIKE :q OR author ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[age_max age_min author cover_image_url created_at description id language publisher_id status title updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[publisher rights_windows video_asset]
  end

  private

  def age_range_valid
    return if age_min.nil? || age_max.nil? || age_min <= age_max

    errors.add(:age_max, "must be greater than or equal to age_min")
  end
end
