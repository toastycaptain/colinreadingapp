ActiveAdmin.register DeletionRequest do
  actions :index, :show

  scope :all
  scope :requested
  scope :processing
  scope :completed
  scope :failed

  index do
    selectable_column
    id_column
    column :user
    column :child_profile
    column :status do |request|
      status_tag(request.status)
    end
    column :requested_at
    column :processed_at
    actions defaults: true do |request|
      if request.requested? || request.failed?
        item "Mark Processing", mark_processing_admin_deletion_request_path(request), method: :post, class: "member_link"
      end
      if request.processing?
        item "Mark Completed", mark_completed_admin_deletion_request_path(request), method: :post, class: "member_link"
        item "Mark Failed", mark_failed_admin_deletion_request_path(request), method: :post, class: "member_link"
      end
    end
  end

  filter :user
  filter :child_profile
  filter :status
  filter :requested_at
  filter :processed_at

  show do
    attributes_table do
      row :id
      row :user
      row :child_profile
      row :status
      row :reason
      row :requested_at
      row :processed_at
      row :created_at
      row :updated_at
      row :metadata do |request|
        pre JSON.pretty_generate(request.metadata || {})
      end
    end
  end

  action_item :mark_processing, only: :show, if: proc { resource.requested? || resource.failed? } do
    link_to "Mark Processing", mark_processing_admin_deletion_request_path(resource), method: :post
  end

  action_item :mark_completed, only: :show, if: proc { resource.processing? } do
    link_to "Mark Completed", mark_completed_admin_deletion_request_path(resource), method: :post
  end

  action_item :mark_failed, only: :show, if: proc { resource.processing? } do
    link_to "Mark Failed", mark_failed_admin_deletion_request_path(resource), method: :post
  end

  member_action :mark_processing, method: :post do
    resource.update!(status: :processing, processed_at: nil)
    redirect_to resource_path, notice: "Deletion request marked as processing."
  end

  member_action :mark_completed, method: :post do
    resource.update!(status: :completed, processed_at: Time.current)
    redirect_to resource_path, notice: "Deletion request marked as completed."
  end

  member_action :mark_failed, method: :post do
    resource.update!(status: :failed, processed_at: Time.current)
    redirect_to resource_path, alert: "Deletion request marked as failed."
  end
end
