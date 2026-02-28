module PublisherPortalAuthorization
  extend ActiveSupport::Concern

  private

  def require_owner!
    return if current_publisher_user&.owner?

    redirect_to publisher_root_path, alert: "Owner access required."
  end

  def require_analytics_access!
    return if current_publisher_user&.can_view_analytics?

    redirect_to publisher_root_path, alert: "Analytics access required."
  end

  def require_statement_access!
    return if current_publisher_user&.can_view_statements?

    redirect_to publisher_root_path, alert: "Finance access required."
  end

  def require_export_access!
    return if current_publisher_user&.can_manage_exports?

    redirect_to publisher_root_path, alert: "Export access required."
  end
end
