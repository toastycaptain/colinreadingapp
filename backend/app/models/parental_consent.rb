class ParentalConsent < ApplicationRecord
  belongs_to :user

  validates :policy_version, :consented_at, presence: true

  scope :active, -> { where(revoked_at: nil) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[consented_at created_at id metadata policy_version revoked_at updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end
end
