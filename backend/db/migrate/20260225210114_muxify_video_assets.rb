class MuxifyVideoAssets < ActiveRecord::Migration[8.1]
  def up
    add_column :video_assets, :mux_asset_id, :string
    add_column :video_assets, :mux_playback_id, :string
    add_column :video_assets, :mux_upload_id, :string
    add_column :video_assets, :playback_policy, :integer, null: false, default: 1
    add_column :video_assets, :mux_error_message, :text

    execute <<~SQL
      UPDATE video_assets
      SET processing_status = CASE processing_status
        WHEN 0 THEN 0
        WHEN 1 THEN 2
        WHEN 2 THEN 3
        WHEN 3 THEN 4
        ELSE 0
      END;
    SQL

    add_index :video_assets, :mux_asset_id, unique: true
    add_index :video_assets, :mux_upload_id
    add_index :video_assets, :playback_policy

    remove_column :video_assets, :master_s3_key, :string
    remove_column :video_assets, :hls_base_path, :string
    remove_column :video_assets, :hls_manifest_path, :string
    remove_column :video_assets, :mediaconvert_job_id, :string
    remove_column :video_assets, :error_message, :text
  end

  def down
    add_column :video_assets, :master_s3_key, :string, null: false, default: ""
    add_column :video_assets, :hls_base_path, :string
    add_column :video_assets, :hls_manifest_path, :string
    add_column :video_assets, :mediaconvert_job_id, :string
    add_column :video_assets, :error_message, :text

    add_index :video_assets, :mediaconvert_job_id, unique: true

    execute <<~SQL
      UPDATE video_assets
      SET processing_status = CASE processing_status
        WHEN 0 THEN 0
        WHEN 1 THEN 0
        WHEN 2 THEN 1
        WHEN 3 THEN 2
        WHEN 4 THEN 3
        ELSE 0
      END;
    SQL

    remove_index :video_assets, :mux_asset_id
    remove_index :video_assets, :mux_upload_id
    remove_index :video_assets, :playback_policy

    remove_column :video_assets, :mux_asset_id, :string
    remove_column :video_assets, :mux_playback_id, :string
    remove_column :video_assets, :mux_upload_id, :string
    remove_column :video_assets, :playback_policy, :integer
    remove_column :video_assets, :mux_error_message, :text
  end
end
