class WebhookEvent < ApplicationRecord
  enum :status, { received: "received", processed: "processed", failed: "failed" }, default: :received, validate: true

  validates :provider, :event_id, :event_type, presence: true
  validates :event_id, uniqueness: { scope: :provider }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at event_id event_type id payload processed_at provider status updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
