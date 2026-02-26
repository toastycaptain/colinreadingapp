class AddPrivacyFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :privacy_policy_version_accepted, :string
    add_column :users, :privacy_policy_accepted_at, :datetime
  end
end
