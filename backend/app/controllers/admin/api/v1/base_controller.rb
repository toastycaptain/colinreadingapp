class Admin::Api::V1::BaseController < ApplicationController
  before_action :authenticate_admin_user!

  private

  def require_content_admin!
    return if current_admin_user&.can_manage_content?

    render_error(code: "forbidden", message: "Content admin role required", status: :forbidden)
  end

  def require_finance_admin!
    return if current_admin_user&.can_manage_finance?

    render_error(code: "forbidden", message: "Finance admin role required", status: :forbidden)
  end

  def require_analytics_admin!
    return if current_admin_user&.can_manage_analytics?

    render_error(code: "forbidden", message: "Analytics admin role required", status: :forbidden)
  end

  def require_compliance_admin!
    return if current_admin_user&.can_manage_compliance?

    render_error(code: "forbidden", message: "Compliance admin role required", status: :forbidden)
  end
end
