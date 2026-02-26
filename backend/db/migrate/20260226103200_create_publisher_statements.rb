class CreatePublisherStatements < ActiveRecord::Migration[8.1]
  def change
    create_table :publisher_statements do |t|
      t.references :payout_period, null: false, foreign_key: true
      t.references :publisher, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.decimal :minutes_watched, precision: 10, scale: 2, null: false, default: 0
      t.integer :play_starts, null: false, default: 0
      t.integer :play_ends, null: false, default: 0
      t.integer :unique_children, null: false, default: 0

      t.integer :gross_revenue_cents, null: false, default: 0
      t.integer :platform_fee_cents, null: false, default: 0
      t.integer :net_revenue_cents, null: false, default: 0
      t.integer :rev_share_bps, null: false, default: 0
      t.integer :payout_amount_cents, null: false, default: 0

      t.string :stripe_transfer_id
      t.datetime :calculated_at
      t.jsonb :breakdown, null: false, default: {}

      t.timestamps
    end

    add_index :publisher_statements, [:payout_period_id, :publisher_id], unique: true
    add_index :publisher_statements, :status
    add_index :publisher_statements, :stripe_transfer_id
  end
end
