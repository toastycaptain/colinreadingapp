ActiveAdmin.register WebhookEvent do
  actions :index, :show

  scope :all
  scope :received
  scope :processed
  scope :failed

  index do
    selectable_column
    id_column
    column :provider
    column :event_id
    column :event_type
    column :status
    column :processed_at
    column :created_at
    actions
  end

  filter :provider
  filter :event_id
  filter :event_type
  filter :status
  filter :processed_at
  filter :created_at

  show do
    attributes_table do
      row :id
      row :provider
      row :event_id
      row :event_type
      row :status
      row :processed_at
      row :created_at
      row :updated_at
      row :payload do |event|
        pre JSON.pretty_generate(event.payload || {})
      end
    end
  end
end
