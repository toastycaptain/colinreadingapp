class CreateParentalConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :parental_consents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :policy_version, null: false
      t.datetime :consented_at, null: false
      t.datetime :revoked_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :parental_consents, [:user_id, :policy_version, :consented_at], name: "idx_parental_consents_user_policy_time"
    add_index :parental_consents, :revoked_at
  end
end
