class Publisher < ApplicationRecord
  enum :status, { active: 0, inactive: 1 }, default: :active

  has_many :books, dependent: :nullify
  has_many :partnership_contracts, dependent: :destroy
  has_many :publisher_statements, dependent: :destroy
  has_many :rights_windows, dependent: :destroy
  has_many :publisher_users, dependent: :destroy
  has_many :data_exports, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :stripe_connect_account_id, uniqueness: true, allow_blank: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[billing_email contact_name created_at id name status stripe_connect_account_id stripe_onboarding_complete updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[books data_exports partnership_contracts publisher_statements publisher_users rights_windows]
  end
end
