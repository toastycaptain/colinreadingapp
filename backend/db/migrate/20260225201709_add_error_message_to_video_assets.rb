class AddErrorMessageToVideoAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :video_assets, :error_message, :text
  end
end
