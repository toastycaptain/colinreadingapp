class CreateVideoAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :video_assets do |t|
      t.references :book, null: false, foreign_key: true, index: false
      t.string :master_s3_key, null: false
      t.string :hls_base_path
      t.string :hls_manifest_path
      t.integer :duration_seconds
      t.string :mediaconvert_job_id
      t.integer :processing_status, null: false, default: 0

      t.timestamps
    end

    add_index :video_assets, :book_id, unique: true
    add_index :video_assets, :mediaconvert_job_id, unique: true
    add_index :video_assets, :processing_status
  end
end
