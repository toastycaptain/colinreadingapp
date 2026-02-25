ActiveAdmin.register VideoAsset do
  permit_params :book_id, :mux_upload_id, :mux_asset_id, :mux_playback_id, :duration_seconds,
                :processing_status, :playback_policy, :mux_error_message

  scope :all
  scope :created
  scope :uploading
  scope :processing
  scope :ready
  scope :failed

  index do
    selectable_column
    id_column
    column :book
    column :processing_status do |asset|
      status_tag asset.processing_status
    end
    column :playback_policy
    column :mux_upload_id
    column :mux_asset_id
    column :mux_playback_id
    column :updated_at
    actions defaults: true do |asset|
      item "Retry Upload", retry_upload_admin_video_asset_path(asset), method: :post, class: "member_link" if asset.failed?
    end
  end

  filter :book
  filter :processing_status
  filter :mux_upload_id
  filter :mux_asset_id
  filter :mux_playback_id

  action_item :retry_upload, only: :show, if: proc { resource.failed? } do
    link_to "Retry Upload", retry_upload_admin_video_asset_path(resource), method: :post
  end

  show do
    attributes_table do
      row :id
      row :book
      row :processing_status
      row :playback_policy
      row :mux_upload_id
      row :mux_asset_id
      row :mux_playback_id
      row :duration_seconds
      row :mux_error_message
      row :created_at
      row :updated_at
      row("Playback HLS URL") do |asset|
        asset.mux_playback_id.present? ? "https://stream.mux.com/#{asset.mux_playback_id}.m3u8" : "Unavailable"
      end
    end
  end

  member_action :retry_upload, method: :post do
    resource.update!(
      processing_status: :created,
      mux_upload_id: nil,
      mux_asset_id: nil,
      mux_playback_id: nil,
      mux_error_message: nil,
    )

    redirect_to upload_master_video_admin_book_path(resource.book), notice: "Ready for a fresh upload."
  end
end
