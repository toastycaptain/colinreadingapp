class Publisher::StatementsController < Publisher::BaseController
  before_action :require_statement_access!
  before_action :set_statement, only: :show

  def index
    @statements = current_publisher.publisher_statements.includes(:payout_period).order(created_at: :desc)
  end

  def show
    AuditLog.record!(
      actor: current_publisher_user,
      action: "view_statement",
      subject: @statement,
      metadata: { path: request.fullpath },
    ) if defined?(AuditLog)

    @breakdown_rows = Array.wrap(@statement.breakdown).select { |row| row.is_a?(Hash) }
  end

  private

  def set_statement
    @statement = current_publisher.publisher_statements.includes(:payout_period).find(params[:id])
  end
end
