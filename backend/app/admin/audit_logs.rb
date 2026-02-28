ActiveAdmin.register AuditLog do
  actions :index, :show
  menu priority: 12

  config.sort_order = "occurred_at_desc"
  config.per_page = 100

  index do
    id_column
    column :occurred_at
    column :action
    column("Actor") { |log| "#{log.actor_type}##{log.actor_id}" }
    column("Subject") { |log| "#{log.subject_type}##{log.subject_id}" }
    actions
  end

  filter :action
  filter :actor_type
  filter :actor_id
  filter :subject_type
  filter :subject_id
  filter :occurred_at

  show do
    attributes_table do
      row :id
      row :occurred_at
      row :action
      row :actor_type
      row :actor_id
      row :subject_type
      row :subject_id
      row :created_at
      row :updated_at
      row :metadata do |log|
        pre JSON.pretty_generate(log.metadata || {})
      end
    end
  end
end
