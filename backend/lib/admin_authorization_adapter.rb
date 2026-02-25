class AdminAuthorizationAdapter < ActiveAdmin::AuthorizationAdapter
  READ_ACTIONS = %i[read index show].freeze
  WRITE_ACTIONS = %i[new create edit update destroy batch_action].freeze

  def authorized?(action, subject = nil)
    return false unless user
    return true if user.super_admin?

    normalized_action = normalize_action(action)

    case user.role.to_sym
    when :content_admin
      content_admin_authorized?(normalized_action, subject)
    when :finance_admin
      finance_admin_authorized?(normalized_action, subject)
    else
      false
    end
  end

  private

  def normalize_action(action)
    return :read if action.in?(READ_ACTIONS)
    return :write if action.in?(WRITE_ACTIONS)

    action.to_sym
  end

  def subject_class(subject)
    case subject
    when Class
      subject
    else
      subject.class
    end
  end

  def page_name(subject)
    return nil unless subject.is_a?(ActiveAdmin::Page)

    subject.name
  end

  def content_admin_authorized?(action, subject)
    return true if page_name(subject) == "Dashboard"

    allowed_classes = [Publisher, Book, RightsWindow, VideoAsset]
    allowed_classes.include?(subject_class(subject))
  end

  def finance_admin_authorized?(action, subject)
    return true if page_name(subject).in?(["Dashboard", "Usage Reports"])

    read_only_classes = [Publisher, PartnershipContract]
    return false unless read_only_classes.include?(subject_class(subject))

    action == :read
  end
end
