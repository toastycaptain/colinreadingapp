ActiveAdmin.register ParentalConsent do
  actions :index, :show

  scope :all
  scope :active

  index do
    selectable_column
    id_column
    column :user
    column :policy_version
    column :consented_at
    column :revoked_at
    column :created_at
    actions
  end

  filter :user
  filter :policy_version
  filter :consented_at
  filter :revoked_at

  show do
    attributes_table do
      row :id
      row :user
      row :policy_version
      row :consented_at
      row :revoked_at
      row :created_at
      row :updated_at
      row :metadata do |consent|
        pre JSON.pretty_generate(consent.metadata || {})
      end
    end
  end
end
