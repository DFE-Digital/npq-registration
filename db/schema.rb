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

ActiveRecord::Schema.define(version: 2022_04_28_100635) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "citext"
  enable_extension "plpgsql"

  create_table "applications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.bigint "lead_provider_id", null: false
    t.text "school_urn"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "ecf_id"
    t.text "headteacher_status"
    t.boolean "eligible_for_funding", default: false, null: false
    t.text "funding_choice"
    t.text "ukprn"
    t.text "teacher_catchment"
    t.text "teacher_catchment_country"
    t.boolean "works_in_school"
    t.string "employer_name"
    t.string "employment_role"
    t.boolean "low_head_count_eligibility", default: false
    t.index ["course_id"], name: "index_applications_on_course_id"
    t.index ["lead_provider_id"], name: "index_applications_on_lead_provider_id"
    t.index ["user_id"], name: "index_applications_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "ecf_id"
    t.text "description"
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
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "lead_providers", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "ecf_id"
  end

  create_table "local_authorities", force: :cascade do |t|
    t.text "ukprn"
    t.text "name"
    t.text "address_1"
    t.text "address_2"
    t.text "address_3"
    t.text "town"
    t.text "county"
    t.text "postcode"
    t.text "postcode_without_spaces"
    t.boolean "high_pupil_premium", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ukprn"], name: "index_local_authorities_on_ukprn"
  end

  create_table "registration_interests", force: :cascade do |t|
    t.citext "email", null: false
    t.boolean "notified", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_registration_interests_on_email", unique: true
  end

  create_table "reports", force: :cascade do |t|
    t.text "identifier", null: false
    t.text "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.boolean "high_pupil_premium", default: false, null: false
    t.text "postcode_without_spaces"
    t.integer "number_of_pupils"
    t.index "to_tsvector('english'::regconfig, COALESCE(name, ''::text))", name: "school_name_search_idx", using: :gin
    t.index ["urn"], name: "index_schools_on_urn"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "ecf_id"
    t.text "trn"
    t.text "full_name"
    t.text "otp_hash"
    t.datetime "otp_expires_at"
    t.date "date_of_birth"
    t.boolean "trn_verified", default: false, null: false
    t.boolean "active_alert", default: false
    t.text "national_insurance_number"
    t.boolean "trn_auto_verified", default: false
    t.boolean "admin", default: false
    t.index ["ecf_id"], name: "index_users_on_ecf_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
