ActiveAdmin.register DataExport do
  actions :index, :show, :new, :create

  permit_params :export_type, :publisher_id, :book_id, :start_date, :end_date, :child_profile_id

  menu priority: 11

  config.sort_order = "created_at_desc"

  index do
    id_column
    column :export_type
    column :status
    column :publisher
    column("Requested By") { |export| "#{export.requested_by_type}##{export.requested_by_id}" }
    column :generated_at
    column :created_at
    actions defaults: true do |export|
      item "Download", download_admin_data_export_path(export), class: "member_link" if export.ready?
    end
  end

  filter :export_type
  filter :status
  filter :publisher
  filter :created_at

  form do |f|
    f.inputs "Create Export" do
      f.input :export_type, as: :select, collection: DataExport.export_types.keys
      f.input :publisher, include_blank: true
      f.input :book_id, as: :select, collection: Book.order(:title).pluck(:title, :id), include_blank: true
      f.input :start_date, as: :string, input_html: { type: "date" }
      f.input :end_date, as: :string, input_html: { type: "date" }
      f.input :child_profile_id, input_html: { type: "number" }
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :export_type
      row :status
      row :publisher
      row("Requested By") { |export| "#{export.requested_by_type}##{export.requested_by_id}" }
      row :generated_at
      row :created_at
      row :updated_at
      row :error_message
      row :params do |export|
        pre JSON.pretty_generate(export.params || {})
      end
    end

    if data_export.ready?
      panel "Download" do
        div do
          link_to "Download CSV", download_admin_data_export_path(data_export), class: "button"
        end
      end
    end
  end

  member_action :download, method: :get do
    export = resource
    unless export.ready? && export.file_path&.exist?
      return redirect_to resource_path, alert: "Export file is not ready."
    end

    AuditLog.record!(
      actor: current_admin_user,
      action: "download_export",
      subject: export,
      metadata: { path: request.fullpath },
    ) if defined?(AuditLog)

    send_file export.file_path,
              filename: File.basename(export.file_path),
              type: "text/csv",
              disposition: "attachment"
  end

  controller do
    def create
      attrs = permitted_params.fetch(:data_export)

      export = DataExport.create!(
        requested_by: current_admin_user,
        export_type: attrs.fetch(:export_type),
        publisher_id: attrs[:publisher_id].presence,
        params: {
          start_date: attrs[:start_date].presence,
          end_date: attrs[:end_date].presence,
          book_id: attrs[:book_id].presence,
          child_profile_id: attrs[:child_profile_id].presence,
        }.compact,
        status: :pending,
      )

      GenerateDataExportJob.perform_later(export.id)
      redirect_to admin_data_export_path(export), notice: "Export generation queued."
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      @data_export = DataExport.new
      render :new, status: :unprocessable_entity
    end
  end
end
