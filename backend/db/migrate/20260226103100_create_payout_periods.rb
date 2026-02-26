class CreatePayoutPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :payout_periods do |t|
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :currency, null: false, default: "USD"
      t.integer :status, null: false, default: 0
      t.integer :total_gross_revenue_cents, null: false, default: 0
      t.integer :total_payout_cents, null: false, default: 0
      t.datetime :calculated_at
      t.datetime :paid_at
      t.text :notes

      t.timestamps
    end

    add_index :payout_periods, [:start_date, :end_date], unique: true
    add_index :payout_periods, :status
  end
end
