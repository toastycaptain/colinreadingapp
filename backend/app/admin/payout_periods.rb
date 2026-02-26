ActiveAdmin.register PayoutPeriod do
  permit_params :start_date, :end_date, :currency, :notes, :status

  scope :all
  scope :draft
  scope :calculating
  scope :ready
  scope :paid
  scope :failed

  index do
    selectable_column
    id_column
    column :start_date
    column :end_date
    column :currency
    column :status do |period|
      status_tag(period.status)
    end
    column :total_gross_revenue_cents
    column :total_payout_cents
    column :calculated_at
    column :paid_at
    actions defaults: true do |period|
      if period.draft? || period.failed?
        item "Generate", generate_statements_admin_payout_period_path(period), method: :post, class: "member_link"
      end
      if period.ready?
        item "Mark Paid", mark_paid_admin_payout_period_path(period), method: :post, class: "member_link"
      end
    end
  end

  filter :start_date
  filter :end_date
  filter :status
  filter :currency

  show do
    attributes_table do
      row :id
      row :start_date
      row :end_date
      row :currency
      row :status
      row :total_gross_revenue_cents
      row :total_payout_cents
      row :calculated_at
      row :paid_at
      row :notes
      row :created_at
      row :updated_at
    end

    panel "Publisher Statements" do
      table_for payout_period.publisher_statements.includes(:publisher).order(payout_amount_cents: :desc) do
        column(:publisher) { |statement| statement.publisher.name }
        column :status
        column :minutes_watched
        column :gross_revenue_cents
        column :platform_fee_cents
        column :net_revenue_cents
        column :rev_share_bps
        column :payout_amount_cents
        column :stripe_transfer_id
      end
    end
  end

  action_item :generate_statements, only: :show, if: proc { resource.draft? || resource.failed? } do
    link_to "Generate Statements", generate_statements_admin_payout_period_path(resource), method: :post
  end

  action_item :mark_paid, only: :show, if: proc { resource.ready? } do
    link_to "Mark Paid", mark_paid_admin_payout_period_path(resource), method: :post
  end

  member_action :generate_statements, method: :post do
    GeneratePayoutStatementsJob.perform_later(resource.id)
    resource.update!(status: :calculating)
    redirect_to resource_path, notice: "Statement generation enqueued"
  end

  member_action :mark_paid, method: :post do
    ProcessStripePayoutJob.perform_later(resource.id)
    redirect_to resource_path, notice: "Payout processing enqueued"
  end
end
