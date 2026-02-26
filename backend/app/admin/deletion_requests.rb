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
    column :status
    column :requested_at
    column :processed_at
    actions
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
end
