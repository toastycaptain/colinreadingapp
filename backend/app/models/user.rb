class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  enum :role, { parent: 0, admin: 1 }, default: :parent

  has_many :child_profiles, dependent: :destroy
  has_many :library_items, foreign_key: :added_by_user_id, inverse_of: :added_by_user
  has_many :parental_consents, dependent: :destroy
  has_many :deletion_requests, dependent: :destroy

  validates :role, presence: true

  def active_parental_consent?
    parental_consents.where(revoked_at: nil).exists?
  end
end
