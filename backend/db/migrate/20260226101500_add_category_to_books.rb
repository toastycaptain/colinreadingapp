class AddCategoryToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :category, :string, null: false, default: "General"
    add_index :books, :category
  end
end
