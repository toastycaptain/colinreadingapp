class PublisherUser < ApplicationRecord
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable

  enum :role, {
    owner: 0,
    finance: 1,
    analytics: 2,
    read_only: 3,
  }, default: :owner

  belongs_to :publisher
  has_many :data_exports, as: :requested_by, dependent: :nullify
  has_many :audit_logs, as: :actor, dependent: :nullify

  validates :role, presence: true

  def can_manage_team?
    owner?
  end

  def can_view_analytics?
    owner? || finance? || analytics? || read_only?
  end

  def can_view_statements?
    owner? || finance?
  end

  def can_manage_exports?
    owner? || finance? || analytics?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id publisher_id role updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[publisher]
  end
end
