class AdminUser < ApplicationRecord
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable

  enum :role, {
    super_admin: 0,
    content_admin: 1,
    finance_admin: 2,
    support_admin: 3,
    analytics_admin: 4,
    compliance_admin: 5,
  }, default: :super_admin

  validates :role, presence: true

  has_many :data_exports, as: :requested_by, dependent: :nullify
  has_many :audit_logs, as: :actor, dependent: :nullify

  def can_manage_content?
    super_admin? || content_admin?
  end

  def can_manage_finance?
    super_admin? || finance_admin?
  end

  def can_manage_support?
    super_admin? || support_admin?
  end

  def can_manage_analytics?
    super_admin? || analytics_admin? || finance_admin?
  end

  def can_manage_compliance?
    super_admin? || compliance_admin?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id role updated_at]
  end
end
