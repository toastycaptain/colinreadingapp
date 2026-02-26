class CreateDeletionRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :deletion_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :child_profile, foreign_key: true
      t.string :status, null: false, default: "requested"
      t.string :reason
      t.datetime :requested_at, null: false
      t.datetime :processed_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :deletion_requests, :status
    add_index :deletion_requests, :requested_at
  end
end
