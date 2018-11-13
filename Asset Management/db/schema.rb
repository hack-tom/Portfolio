# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180320144252) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.date "start_date"
    t.time "start_time"
    t.date "end_date"
    t.time "end_time"
    t.datetime "start_datetime"
    t.datetime "end_datetime"
    t.string "reason"
    t.string "next_location"
    t.integer "status"
    t.string "peripherals"
    t.bigint "item_id"
    t.bigint "combined_booking_id"
    t.bigint "user_id"
    t.index ["combined_booking_id"], name: "index_bookings_on_combined_booking_id"
    t.index ["item_id"], name: "index_bookings_on_item_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "icon"
    t.boolean "has_peripheral"
    t.boolean "is_peripheral"
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "combined_bookings", force: :cascade do |t|
    t.integer "status"
    t.integer "owner_id"
    t.bigint "user_id"
    t.index ["user_id"], name: "index_combined_bookings_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "item_peripherals", force: :cascade do |t|
    t.bigint "parent_item_id"
    t.bigint "peripheral_item_id"
    t.index ["parent_item_id", "peripheral_item_id"], name: "index_item_peripherals_on_parent_item_id_and_peripheral_item_id", unique: true
    t.index ["parent_item_id"], name: "index_item_peripherals_on_parent_item_id"
    t.index ["peripheral_item_id"], name: "index_item_peripherals_on_peripheral_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.string "condition"
    t.string "location"
    t.string "manufacturer"
    t.string "model"
    t.string "serial"
    t.date "acquisition_date"
    t.decimal "purchase_price"
    t.string "image"
    t.string "keywords"
    t.string "po_number"
    t.string "condition_info"
    t.string "comment"
    t.date "retired_date"
    t.bigint "user_id"
    t.bigint "category_id"
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["serial"], name: "index_items_on_serial", unique: true
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "recipient_id"
    t.string "context"
    t.datetime "read_at"
    t.string "action"
    t.integer "notifiable_id"
    t.string "notifiable_type"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "user_home_categories", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "category_id"
    t.index ["category_id"], name: "index_user_home_categories_on_category_id"
    t.index ["user_id"], name: "index_user_home_categories_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "phone"
    t.integer "permission_id"
    t.string "email", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "username"
    t.string "uid"
    t.string "mail"
    t.string "ou"
    t.string "dn"
    t.string "sn"
    t.string "givenname"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "bookings", "combined_bookings"
  add_foreign_key "bookings", "items"
  add_foreign_key "bookings", "users"
  add_foreign_key "combined_bookings", "users"
  add_foreign_key "item_peripherals", "items", column: "parent_item_id"
  add_foreign_key "item_peripherals", "items", column: "peripheral_item_id"
  add_foreign_key "items", "categories"
  add_foreign_key "items", "users"
  add_foreign_key "user_home_categories", "categories"
  add_foreign_key "user_home_categories", "users"
end
