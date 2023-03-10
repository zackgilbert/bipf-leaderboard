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

ActiveRecord::Schema[7.0].define(version: 2023_03_10_021918) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "provider", default: "twitter", null: false
    t.string "provider_id"
    t.string "body"
    t.string "posted_at"
    t.text "provider_post_raw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_id"], name: "index_posts_on_provider_and_provider_id", unique: true
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "avatar_url"
    t.string "twitter_id"
    t.string "twitter_username"
    t.string "twitter_access_token"
    t.string "twitter_token_secret"
    t.datetime "twitter_last_synced_at"
    t.text "twitter_last_error"
    t.text "twitter_profile_raw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "posts", "users"
end
