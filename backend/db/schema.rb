# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_25_201709) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_admin_users_on_role"
  end

  create_table "books", force: :cascade do |t|
    t.integer "age_max"
    t.integer "age_min"
    t.string "author", null: false
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "language", default: "en", null: false
    t.bigint "publisher_id"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["publisher_id", "status"], name: "index_books_on_publisher_id_and_status"
    t.index ["publisher_id"], name: "index_books_on_publisher_id"
    t.index ["status"], name: "index_books_on_status"
    t.index ["title"], name: "index_books_on_title"
  end

  create_table "child_profiles", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "pin_hash"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_child_profiles_on_user_id_and_name"
    t.index ["user_id"], name: "index_child_profiles_on_user_id"
  end

  create_table "library_items", force: :cascade do |t|
    t.bigint "added_by_user_id", null: false
    t.bigint "book_id", null: false
    t.bigint "child_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_user_id"], name: "index_library_items_on_added_by_user_id"
    t.index ["book_id"], name: "index_library_items_on_book_id"
    t.index ["child_profile_id", "book_id"], name: "index_library_items_on_child_profile_id_and_book_id", unique: true
    t.index ["child_profile_id"], name: "index_library_items_on_child_profile_id"
  end

  create_table "partnership_contracts", force: :cascade do |t|
    t.string "contract_name", null: false
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.integer "minimum_guarantee_cents"
    t.text "notes"
    t.integer "payment_model", default: 0, null: false
    t.bigint "publisher_id", null: false
    t.integer "rev_share_bps", default: 0, null: false
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_partnership_contracts_on_end_date"
    t.index ["publisher_id", "status"], name: "index_partnership_contracts_on_publisher_id_and_status"
    t.index ["publisher_id"], name: "index_partnership_contracts_on_publisher_id"
  end

  create_table "playback_sessions", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "child_profile_id", null: false
    t.text "cloudfront_policy"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "issued_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_playback_sessions_on_book_id"
    t.index ["child_profile_id", "book_id", "expires_at"], name: "idx_playback_sessions_child_book_expires"
    t.index ["child_profile_id"], name: "index_playback_sessions_on_child_profile_id"
  end

  create_table "publishers", force: :cascade do |t|
    t.string "billing_email"
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_publishers_on_name", unique: true
    t.index ["status"], name: "index_publishers_on_status"
  end

  create_table "rights_windows", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "end_at", null: false
    t.bigint "publisher_id", null: false
    t.datetime "start_at", null: false
    t.string "territory", default: "GLOBAL", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "start_at", "end_at"], name: "index_rights_windows_on_book_id_and_start_at_and_end_at"
    t.index ["book_id"], name: "index_rights_windows_on_book_id"
    t.index ["publisher_id", "start_at", "end_at"], name: "index_rights_windows_on_publisher_id_and_start_at_and_end_at"
    t.index ["publisher_id"], name: "index_rights_windows_on_publisher_id"
  end

  create_table "usage_events", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "child_profile_id", null: false
    t.datetime "created_at", null: false
    t.integer "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.integer "position_seconds"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_usage_events_on_book_id"
    t.index ["child_profile_id", "book_id", "occurred_at"], name: "idx_usage_events_child_book_occurred"
    t.index ["child_profile_id"], name: "index_usage_events_on_child_profile_id"
    t.index ["event_type"], name: "index_usage_events_on_event_type"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "video_assets", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.text "error_message"
    t.string "hls_base_path"
    t.string "hls_manifest_path"
    t.string "master_s3_key", null: false
    t.string "mediaconvert_job_id"
    t.integer "processing_status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_video_assets_on_book_id", unique: true
    t.index ["mediaconvert_job_id"], name: "index_video_assets_on_mediaconvert_job_id", unique: true
    t.index ["processing_status"], name: "index_video_assets_on_processing_status"
  end

  add_foreign_key "books", "publishers"
  add_foreign_key "child_profiles", "users"
  add_foreign_key "library_items", "books"
  add_foreign_key "library_items", "child_profiles"
  add_foreign_key "library_items", "users", column: "added_by_user_id"
  add_foreign_key "partnership_contracts", "publishers"
  add_foreign_key "playback_sessions", "books"
  add_foreign_key "playback_sessions", "child_profiles"
  add_foreign_key "rights_windows", "books"
  add_foreign_key "rights_windows", "publishers"
  add_foreign_key "usage_events", "books"
  add_foreign_key "usage_events", "child_profiles"
  add_foreign_key "video_assets", "books"
end
