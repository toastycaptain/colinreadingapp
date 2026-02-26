class AddStripeFieldsToPublishers < ActiveRecord::Migration[8.1]
  def change
    add_column :publishers, :stripe_connect_account_id, :string
    add_column :publishers, :stripe_onboarding_complete, :boolean, null: false, default: false

    add_index :publishers, :stripe_connect_account_id, unique: true
  end
end
