class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.text :description
      t.integer :age_min
      t.integer :age_max
      t.string :language, null: false, default: "en"
      t.string :cover_image_url
      t.references :publisher, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :books, :status
    add_index :books, [:publisher_id, :status]
    add_index :books, :title
  end
end
