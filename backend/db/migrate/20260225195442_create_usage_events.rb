class CreateUsageEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :usage_events do |t|
      t.references :child_profile, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :event_type, null: false
      t.integer :position_seconds
      t.datetime :occurred_at, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :usage_events, [:child_profile_id, :book_id, :occurred_at], name: "idx_usage_events_child_book_occurred"
    add_index :usage_events, :event_type
  end
end
