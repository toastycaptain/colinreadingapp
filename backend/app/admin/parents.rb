ActiveAdmin.register User, as: "Parent" do
  actions :index, :show
  menu label: "Parents", priority: 4

  config.sort_order = "created_at_desc"
  config.per_page = 50

  includes :child_profiles, :parental_consents

  index do
    id_column
    column :email
    column("Children") { |parent| parent.child_profiles.size }
    column("Latest Consent") { |parent| parent.parental_consents.maximum(:policy_version) }
    column :created_at
    actions defaults: true do |parent|
      item "Children", admin_child_profiles_path(q: { user_id_eq: parent.id }), class: "member_link"
    end
  end

  filter :id
  filter :email
  filter :created_at

  show do
    attributes_table do
      row :id
      row :email
      row :created_at
      row :updated_at
      row("Privacy Policy Version") { |parent| parent.privacy_policy_version_accepted }
      row("Privacy Policy Accepted At") { |parent| parent.privacy_policy_accepted_at }
    end

    panel "Children" do
      table_for parent.child_profiles.order(:created_at) do
        column(:id) { |child| link_to(child.id, admin_child_profile_path(child)) }
        column :name
        column("Books in Library") { |child| child.books.count }
        column :created_at
      end
    end

    panel "Parental Consents" do
      table_for parent.parental_consents.order(consented_at: :desc).limit(20) do
        column :policy_version
        column :consented_at
        column :revoked_at
      end
    end

    panel "Deletion Requests" do
      table_for parent.deletion_requests.includes(:child_profile).order(requested_at: :desc).limit(20) do
        column(:id) { |request| link_to(request.id, admin_deletion_request_path(request)) }
        column("Child") { |request| request.child_profile&.name || "All data" }
        column :status
        column :requested_at
        column :processed_at
      end
    end
  end
end
