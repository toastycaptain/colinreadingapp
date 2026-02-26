ActiveAdmin.register PublisherStatement do
  actions :index, :show

  scope :all
  scope :draft
  scope :approved
  scope :paid
  scope :failed

  index do
    selectable_column
    id_column
    column :payout_period
    column :publisher
    column :status
    column :minutes_watched
    column :gross_revenue_cents
    column :net_revenue_cents
    column :rev_share_bps
    column :payout_amount_cents
    column :stripe_transfer_id
    actions
  end

  filter :payout_period
  filter :publisher
  filter :status

  show do
    attributes_table do
      row :id
      row :payout_period
      row :publisher
      row :status
      row :minutes_watched
      row :play_starts
      row :play_ends
      row :unique_children
      row :gross_revenue_cents
      row :platform_fee_cents
      row :net_revenue_cents
      row :rev_share_bps
      row :payout_amount_cents
      row :stripe_transfer_id
      row :calculated_at
      row :created_at
      row :updated_at
      row :breakdown do |statement|
        pre JSON.pretty_generate(statement.breakdown || {})
      end
    end
  end
end
