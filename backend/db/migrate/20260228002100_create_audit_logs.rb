class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.string :actor_type
      t.bigint :actor_id
      t.string :action, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :audit_logs, [:actor_type, :actor_id]
    add_index :audit_logs, [:subject_type, :subject_id]
    add_index :audit_logs, :action
    add_index :audit_logs, :occurred_at
  end
end
