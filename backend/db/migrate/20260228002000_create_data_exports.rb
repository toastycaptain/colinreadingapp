class CreateDataExports < ActiveRecord::Migration[8.1]
  def change
    create_table :data_exports do |t|
      t.string :requested_by_type, null: false
      t.bigint :requested_by_id, null: false
      t.references :publisher, null: true, foreign_key: true
      t.integer :export_type, null: false
      t.jsonb :params, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.text :error_message
      t.datetime :generated_at
      t.string :file_url

      t.timestamps
    end

    add_index :data_exports, [:requested_by_type, :requested_by_id], name: "index_data_exports_on_requested_by"
    add_index :data_exports, :status
  end
end
