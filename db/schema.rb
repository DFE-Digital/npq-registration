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

ActiveRecord::Schema.define(version: 2021_06_03_153706) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "schools", force: :cascade do |t|
    t.text "urn", null: false
    t.text "la_code"
    t.text "la_name"
    t.text "establishment_number"
    t.text "name"
    t.text "establishment_status_code"
    t.text "establishment_status_name"
    t.date "close_date"
    t.text "ukprn"
    t.date "last_changed_date"
    t.text "address_1"
    t.text "address_2"
    t.text "address_3"
    t.text "town"
    t.text "county"
    t.text "postcode"
    t.integer "easting"
    t.integer "northing"
    t.text "region"
    t.text "country"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "establishment_type_code"
    t.text "establishment_type_name"
    t.index ["urn"], name: "index_schools_on_urn"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "ecf_id"
    t.text "trn"
    t.text "first_name"
    t.text "last_name"
    t.text "otp_hash"
    t.datetime "otp_expires_at"
    t.index ["ecf_id"], name: "index_users_on_ecf_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
