class AddWatchFieldsToUsageEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :usage_events, :playback_session, null: true, foreign_key: { on_delete: :nullify }
    add_column :usage_events, :watched_seconds, :integer
    add_column :usage_events, :client_event_id, :string

    add_index :usage_events, :client_event_id, unique: true, where: "client_event_id IS NOT NULL"
  end
end
