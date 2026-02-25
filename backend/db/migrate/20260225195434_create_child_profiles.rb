class CreateChildProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :child_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :avatar_url
      t.string :pin_hash

      t.timestamps
    end

    add_index :child_profiles, [:user_id, :name]
  end
end
