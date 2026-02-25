class CreateRightsWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :rights_windows do |t|
      t.references :publisher, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.string :territory, null: false, default: "GLOBAL"

      t.timestamps
    end

    add_index :rights_windows, [:book_id, :start_at, :end_at]
    add_index :rights_windows, [:publisher_id, :start_at, :end_at]
  end
end
