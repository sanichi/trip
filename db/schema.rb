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

ActiveRecord::Schema[8.1].define(version: 2025_11_01_113643) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "days", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.boolean "draft", default: true
    t.text "notes"
    t.string "title", limit: 50
    t.bigint "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id", "date"], name: "index_days_on_trip_id_and_date", unique: true
    t.index ["trip_id"], name: "index_days_on_trip_id"
  end

  create_table "notes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "draft", default: true
    t.text "markdown"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "trips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date"
    t.date "start_date"
    t.string "title", limit: 50
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_trips_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "last_otp_at"
    t.string "name"
    t.boolean "otp_required", default: false
    t.string "otp_secret", limit: 32
    t.string "password_digest"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "days", "trips"
  add_foreign_key "notes", "users"
  add_foreign_key "trips", "users"
end
