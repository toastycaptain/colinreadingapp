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
    end

    panel "Book Breakdown" do
      rows = Array.wrap(publisher_statement.breakdown).select do |row|
        row.is_a?(Hash) && (row["book_id"].present? || row[:book_id].present? || row["book_title"].present? || row[:book_title].present?)
      end

      if rows.empty?
        div "No breakdown rows recorded."
      else
        table_for rows do
          column("Book") do |row|
            book_id = row["book_id"] || row[:book_id]
            book_title = row["book_title"] || row[:book_title]

            if book_id.present?
              link_to(book_title, admin_book_path(book_id))
            else
              book_title
            end
          end
          column("Minutes Watched") { |row| format("%.2f", (row["minutes_watched"] || row[:minutes_watched]).to_f) }
          column("Gross Revenue (cents)") { |row| row["gross_revenue_cents"] || row[:gross_revenue_cents] }
        end
      end
    end

    panel "Raw Breakdown JSON" do
      pre JSON.pretty_generate(publisher_statement.breakdown || {})
    end
  end
end
