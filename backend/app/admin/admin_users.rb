ActiveAdmin.register AdminUser do
  permit_params :email, :password, :password_confirmation, :role

  config.filters = true

  index do
    selectable_column
    id_column
    column :email
    column :role
    column :created_at
    actions
  end

  filter :email
  filter :role
  filter :created_at

  form do |f|
    f.inputs "Admin User Details" do
      f.input :email
      f.input :role, as: :select, collection: AdminUser.roles.keys
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :role
      row :created_at
      row :updated_at
    end
  end

  controller do
    def scoped_collection
      super.order(created_at: :desc)
    end
  end
end
