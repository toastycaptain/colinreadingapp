class CreatePublishers < ActiveRecord::Migration[8.1]
  def change
    create_table :publishers do |t|
      t.string :name, null: false
      t.string :billing_email
      t.string :contact_name
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :publishers, :name, unique: true
    add_index :publishers, :status
  end
end
