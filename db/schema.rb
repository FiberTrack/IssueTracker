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

ActiveRecord::Schema[7.0].define(version: 2023_05_09_073011) do
  create_table "activities", force: :cascade do |t|
    t.integer "user_id"
    t.integer "issue_id"
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "attachments", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.integer "issue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_attachments_on_issue_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.integer "issue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", default: 1, null: false
    t.index ["issue_id"], name: "index_comments_on_issue_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "issue_watchers", force: :cascade do |t|
    t.integer "issue_id", null: false
    t.integer "user_id", null: false
    t.index ["issue_id"], name: "index_issue_watchers_on_issue_id"
    t.index ["user_id"], name: "index_issue_watchers_on_user_id"
  end

  create_table "issues", force: :cascade do |t|
    t.string "subject"
    t.text "description"
    t.string "assign"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "severity"
    t.string "priority"
    t.string "issue_types"
    t.string "issue_type"
    t.boolean "blocked"
    t.date "deadline"
    t.string "watcher"
    t.text "watcher_ids"
    t.string "status"
    t.string "created_by"
  end

  create_table "issues_users", id: false, force: :cascade do |t|
    t.integer "issue_id", null: false
    t.integer "user_id", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name"
    t.string "uid"
    t.string "avatar_url"
    t.string "provider"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "bio"
    t.string "api_key"
  end

  add_foreign_key "attachments", "issues"
  add_foreign_key "comments", "issues"
  add_foreign_key "comments", "users"
  add_foreign_key "issue_watchers", "issues"
  add_foreign_key "issue_watchers", "users"
end
