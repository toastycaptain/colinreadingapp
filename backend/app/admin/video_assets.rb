ActiveAdmin.register VideoAsset do
  permit_params :book_id, :master_s3_key, :hls_base_path, :hls_manifest_path, :duration_seconds,
                :mediaconvert_job_id, :processing_status, :error_message

  scope :all
  scope :uploaded
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
    column :mediaconvert_job_id
    column :hls_manifest_path
    column :updated_at
    actions defaults: true do |asset|
      item "Retry", retry_processing_admin_video_asset_path(asset), method: :post, class: "member_link" if asset.failed?
      item "Poll", poll_status_admin_video_asset_path(asset), method: :post, class: "member_link" if asset.processing?
    end
  end

  filter :book
  filter :processing_status
  filter :mediaconvert_job_id

  action_item :retry_processing, only: :show, if: proc { resource.failed? } do
    link_to "Retry MediaConvert", retry_processing_admin_video_asset_path(resource), method: :post
  end

  action_item :poll_status, only: :show, if: proc { resource.processing? } do
    link_to "Poll Status Now", poll_status_admin_video_asset_path(resource), method: :post
  end

  show do
    attributes_table do
      row :id
      row :book
      row :master_s3_key
      row :processing_status
      row :mediaconvert_job_id
      row :hls_base_path
      row :hls_manifest_path
      row :duration_seconds
      row :error_message
      row :created_at
      row :updated_at
    end
  end

  member_action :retry_processing, method: :post do
    resource.update!(processing_status: :uploaded, error_message: nil)
    MediaConvertCreateJob.perform_later(resource.id)
    redirect_to resource_path, notice: "MediaConvert job re-enqueued"
  end

  member_action :poll_status, method: :post do
    MediaConvertPollJob.perform_now(resource.id)
    redirect_to resource_path, notice: "Video asset status refreshed"
  end
end
