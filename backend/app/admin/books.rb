ActiveAdmin.register Book do
  permit_params :title, :author, :description, :age_min, :age_max, :language, :cover_image_url,
                :publisher_id, :status

  scope :all
  scope :draft
  scope :active
  scope :inactive

  index do
    selectable_column
    id_column
    column :title
    column :author
    column :publisher
    column :status
    column :age_min
    column :age_max
    column("Video") { |book| status_tag(book.video_asset&.processing_status || "missing") }
    actions defaults: true do |book|
      item "Upload", upload_master_video_admin_book_path(book), class: "member_link"
    end
  end

  filter :title
  filter :author
  filter :publisher
  filter :status
  filter :language

  action_item :upload_master_video, only: :show do
    link_to "Upload Master Video", upload_master_video_admin_book_path(resource)
  end

  show do
    attributes_table do
      row :id
      row :title
      row :author
      row :description
      row :age_min
      row :age_max
      row :language
      row :cover_image_url
      row :publisher
      row :status
      row :created_at
      row :updated_at
    end

    panel "Rights Windows" do
      table_for book.rights_windows.order(start_at: :desc) do
        column :territory
        column :start_at
        column :end_at
        column do |rights_window|
          link_to "View", admin_rights_window_path(rights_window)
        end
      end
      div do
        link_to "Create Rights Window", new_admin_rights_window_path(rights_window: { book_id: book.id, publisher_id: book.publisher_id })
      end
    end

    panel "Video Asset" do
      if book.video_asset.present?
        attributes_table_for book.video_asset do
          row :processing_status
          row :master_s3_key
          row :mediaconvert_job_id
          row :hls_manifest_path
          row :error_message
          row("Playback Manifest URL") do |asset|
            if asset.hls_manifest_path.present? && ENV["CLOUDFRONT_DOMAIN"].present?
              "https://#{ENV['CLOUDFRONT_DOMAIN']}/#{asset.hls_manifest_path}"
            else
              "Unavailable"
            end
          end
        end
      else
        div "No video asset registered yet."
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :author
      f.input :description
      f.input :age_min
      f.input :age_max
      f.input :language
      f.input :cover_image_url
      f.input :publisher
      f.input :status
    end
    f.actions
  end

  member_action :upload_master_video, method: :get do
    @book = resource
    render "admin/books/upload_master_video"
  end
end
