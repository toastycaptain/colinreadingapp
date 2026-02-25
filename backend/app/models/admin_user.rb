class AdminUser < ApplicationRecord
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable

  enum :role, { super_admin: 0, content_admin: 1, finance_admin: 2 }, default: :super_admin

  validates :role, presence: true

  def can_manage_content?
    super_admin? || content_admin?
  end

  def can_manage_finance?
    super_admin? || finance_admin?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id role updated_at]
  end
end
