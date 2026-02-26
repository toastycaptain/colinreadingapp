class CreateDailyMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_metrics do |t|
      t.date :metric_date, null: false
      t.references :publisher, foreign_key: true
      t.references :book, foreign_key: true
      t.integer :play_starts, null: false, default: 0
      t.integer :play_ends, null: false, default: 0
      t.integer :unique_children, null: false, default: 0
      t.decimal :minutes_watched, precision: 12, scale: 2, null: false, default: 0
      t.decimal :avg_completion_rate, precision: 6, scale: 4, null: false, default: 0

      t.timestamps
    end

    add_index :daily_metrics, [:metric_date, :publisher_id, :book_id], unique: true, name: "idx_daily_metrics_date_pub_book"
    add_index :daily_metrics, :metric_date
  end
end
