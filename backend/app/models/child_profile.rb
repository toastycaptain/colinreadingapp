class ChildProfile < ApplicationRecord
  belongs_to :user

  has_many :library_items, dependent: :destroy
  has_many :books, through: :library_items
  has_many :playback_sessions, dependent: :destroy
  has_many :usage_events, dependent: :destroy
  has_many :deletion_requests, dependent: :nullify

  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[avatar_url created_at id name pin_hash updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[books deletion_requests library_items usage_events user]
  end
end
