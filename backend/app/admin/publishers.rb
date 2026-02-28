ActiveAdmin.register Publisher do
  permit_params :name, :billing_email, :contact_name, :status, :stripe_connect_account_id, :stripe_onboarding_complete

  scope :all
  scope :active
  scope :inactive

  index do
    selectable_column
    id_column
    column :name
    column :billing_email
    column :contact_name
    column :status
    column :stripe_connect_account_id
    column :stripe_onboarding_complete
    column("Contracts") { |publisher| publisher.partnership_contracts.count }
    column("Books") { |publisher| publisher.books.count }
    actions defaults: true do |publisher|
      item "Usage", admin_usage_reports_path(publisher_id: publisher.id), class: "member_link"
    end
  end

  filter :name
  filter :billing_email
  filter :status
  filter :stripe_connect_account_id

  form do |f|
    f.inputs do
      f.input :name
      f.input :billing_email
      f.input :contact_name
      f.input :status
      f.input :stripe_connect_account_id
      f.input :stripe_onboarding_complete
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :billing_email
      row :contact_name
      row :status
      row :stripe_connect_account_id
      row :stripe_onboarding_complete
      row :created_at
      row :updated_at
    end

    panel "Contracts" do
      table_for publisher.partnership_contracts.order(created_at: :desc).limit(10) do
        column(:id) { |contract| link_to(contract.id, admin_partnership_contract_path(contract)) }
        column :contract_name
        column :payment_model
        column :status
        column :start_date
        column :end_date
      end
    end

    panel "Books" do
      table_for publisher.books.order(created_at: :desc).limit(10) do
        column(:id) { |book| link_to(book.id, admin_book_path(book)) }
        column :title
        column :author
        column :status
      end
    end

    panel "Publisher Users" do
      table_for publisher.publisher_users.order(created_at: :desc).limit(10) do
        column(:id) { |user| link_to(user.id, admin_publisher_user_path(user)) }
        column :email
        column :role
        column :created_at
      end
      div do
        link_to "Invite Publisher User", new_admin_publisher_user_path(publisher_user: { publisher_id: publisher.id })
      end
    end
  end
end
