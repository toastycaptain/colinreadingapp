class CreatePlaybackSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :playback_sessions do |t|
      t.references :child_profile, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.datetime :issued_at, null: false
      t.datetime :expires_at, null: false
      t.text :cloudfront_policy

      t.timestamps
    end

    add_index :playback_sessions, [:child_profile_id, :book_id, :expires_at], name: "idx_playback_sessions_child_book_expires"
  end
end
