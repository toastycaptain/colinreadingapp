class CreatePublisherUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :publisher_users do |t|
      t.references :publisher, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.timestamps null: false
    end

    add_index :publisher_users, :email, unique: true
    add_index :publisher_users, :reset_password_token, unique: true
    add_index :publisher_users, [:publisher_id, :role]
  end
end
