ActiveAdmin.register PublisherUser do
  permit_params :publisher_id, :email, :role, :password, :password_confirmation

  menu priority: 7

  index do
    selectable_column
    id_column
    column :publisher
    column :email
    column :role
    column :created_at
    actions
  end

  filter :publisher
  filter :email
  filter :role
  filter :created_at

  form do |f|
    f.inputs do
      f.input :publisher
      f.input :email
      f.input :role, as: :select, collection: PublisherUser.roles.keys
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :publisher
      row :email
      row :role
      row :created_at
      row :updated_at
    end
  end

  action_item :send_reset, only: :show do
    link_to "Send Password Reset", send_password_reset_admin_publisher_user_path(resource), method: :post
  end

  member_action :send_password_reset, method: :post do
    resource.send_reset_password_instructions
    redirect_to resource_path, notice: "Password reset instructions sent."
  end
end
