class AuditLog < ApplicationRecord
  belongs_to :actor, polymorphic: true, optional: true
  belongs_to :subject, polymorphic: true, optional: true

  validates :action, :occurred_at, presence: true

  before_validation :set_occurred_at, on: :create

  def self.record!(actor:, action:, subject: nil, metadata: {})
    create!(
      actor: actor,
      action: action,
      subject: subject,
      metadata: metadata || {},
      occurred_at: Time.current,
    )
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[action actor_id actor_type created_at id metadata occurred_at subject_id subject_type updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end
end
