class CreateLibraryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :library_items do |t|
      t.references :child_profile, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.bigint :added_by_user_id, null: false

      t.timestamps
    end

    add_foreign_key :library_items, :users, column: :added_by_user_id
    add_index :library_items, [:child_profile_id, :book_id], unique: true
    add_index :library_items, :added_by_user_id
  end
end
