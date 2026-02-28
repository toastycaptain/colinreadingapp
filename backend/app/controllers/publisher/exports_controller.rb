class Publisher::ExportsController < Publisher::BaseController
  before_action :require_export_access!
  before_action :set_data_export, only: [:show, :download]

  def index
    @data_exports = current_publisher.data_exports.order(created_at: :desc).limit(200)
  end

  def create
    export_type = params.require(:export_type)
    unless export_type.in?(%w[analytics_daily statement_breakdown])
      return redirect_to publisher_exports_path, alert: "Unsupported export type."
    end

    data_export = current_publisher.data_exports.create!(
      requested_by: current_publisher_user,
      export_type: export_type,
      params: export_params,
      status: :pending,
    )

    GenerateDataExportJob.perform_later(data_export.id)

    redirect_to publisher_export_path(data_export), notice: "Export requested."
  end

  def show
  end

  def download
    unless @data_export.ready? && @data_export.file_path&.exist?
      return redirect_to publisher_export_path(@data_export), alert: "Export file is not ready."
    end

    AuditLog.record!(
      actor: current_publisher_user,
      action: "download_export",
      subject: @data_export,
      metadata: { path: request.fullpath },
    ) if defined?(AuditLog)

    send_file @data_export.file_path,
              filename: File.basename(@data_export.file_path),
              type: "text/csv",
              disposition: "attachment"
  end

  private

  def set_data_export
    @data_export = current_publisher.data_exports.find(params[:id])
  end

  def export_params
    {
      start_date: params[:start_date],
      end_date: params[:end_date],
      book_id: params[:book_id],
    }.compact
  end
end
