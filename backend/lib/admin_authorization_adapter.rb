class AdminAuthorizationAdapter < ActiveAdmin::AuthorizationAdapter
  READ_ACTIONS = %i[read index show].freeze
  WRITE_ACTIONS = %i[new create edit update destroy batch_action].freeze
  ANALYTICS_PAGES = ["Usage Reports", "Analytics Dashboard"].freeze
  PAYOUT_WRITE_ACTIONS = %i[write generate_statements mark_paid rerun].freeze
  DELETION_WRITE_ACTIONS = %i[write mark_processing mark_completed mark_failed].freeze

  def authorized?(action, subject = nil)
    return false unless user
    return true if user.super_admin?

    normalized_action = normalize_action(action)
    subject_name = subject_name(subject)
    page = page_name(subject)

    case user.role.to_sym
    when :content_admin
      content_admin_authorized?(normalized_action, subject_name, page)
    when :finance_admin
      finance_admin_authorized?(normalized_action, subject_name, page)
    when :support_admin
      support_admin_authorized?(normalized_action, subject_name, page)
    when :analytics_admin
      analytics_admin_authorized?(normalized_action, subject_name, page)
    when :compliance_admin
      compliance_admin_authorized?(normalized_action, subject_name, page)
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

  def subject_name(subject)
    subject_class(subject).name
  end

  def page_name(subject)
    return nil unless subject.is_a?(ActiveAdmin::Page)

    subject.name
  end

  def content_admin_authorized?(action, subject_name, page)
    return true if page == "Dashboard"

    return true if %w[Publisher PublisherUser Book RightsWindow VideoAsset PartnershipContract].include?(subject_name)

    action == :upload_master_video && subject_name == "Book"
  end

  def finance_admin_authorized?(action, subject_name, page)
    return true if page == "Dashboard" || ANALYTICS_PAGES.include?(page)
    return true if subject_name == "PayoutPeriod" && action.in?(PAYOUT_WRITE_ACTIONS)
    return true if subject_name == "PublisherStatement" && action == :read
    return true if subject_name.in?(%w[Publisher PartnershipContract]) && action == :read
    return true if subject_name == "DataExport"

    false
  end

  def support_admin_authorized?(action, subject_name, page)
    return true if page == "Dashboard" || page == "Usage Reports"
    return false unless action == :read

    subject_name.in?(%w[User ChildProfile UsageEvent])
  end

  def analytics_admin_authorized?(action, subject_name, page)
    return true if page == "Dashboard" || ANALYTICS_PAGES.include?(page)
    return true if subject_name == "DataExport"
    return false unless action == :read

    subject_name.in?(%w[Publisher Book DailyMetric])
  end

  def compliance_admin_authorized?(action, subject_name, page)
    return true if page == "Dashboard"
    return true if subject_name == "ParentalConsent" && action == :read
    return true if subject_name == "DeletionRequest" && action.in?(DELETION_WRITE_ACTIONS)
    return true if subject_name == "AuditLog" && action == :read

    false
  end
end
