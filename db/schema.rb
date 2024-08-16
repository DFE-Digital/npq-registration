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

ActiveRecord::Schema[7.1].define(version: 2024_08_14_095351) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "citext"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "application_statuses", ["active", "deferred", "withdrawn"]
  create_enum "declaration_state_reasons", ["duplicate"]
  create_enum "declaration_states", ["submitted", "eligible", "payable", "paid", "voided", "ineligible", "awaiting_clawback", "clawed_back"]
  create_enum "declaration_types", ["started", "retained-1", "retained-2", "completed"]
  create_enum "funding_choices", ["school", "trust", "self", "another", "employer"]
  create_enum "headteacher_statuses", ["no", "yes_when_course_starts", "yes_in_first_two_years", "yes_over_two_years", "yes_in_first_five_years", "yes_over_five_years"]
  create_enum "kind_of_nurseries", ["local_authority_maintained_nursery", "preschool_class_as_part_of_school", "private_nursery", "another_early_years_setting", "childminder"]
  create_enum "lead_provider_approval_statuses", ["pending", "accepted", "rejected"]
  create_enum "outcome_states", ["passed", "failed", "voided"]
  create_enum "schedule_declaration_types", ["started", "retained-1", "retained-2", "completed"]
  create_enum "statement_item_states", ["eligible", "payable", "paid", "voided", "ineligible", "awaiting_clawback", "clawed_back"]
  create_enum "statement_states", ["open", "payable", "paid"]

  create_table "admins", force: :cascade do |t|
    t.string "email", limit: 64, null: false
    t.string "full_name", limit: 64, null: false
    t.boolean "super_admin", default: false, null: false
    t.text "otp_hash"
    t.datetime "otp_expires_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "lead_provider_id", null: false
    t.string "hashed_token", null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hashed_token"], name: "index_api_tokens_on_hashed_token", unique: true
    t.index ["lead_provider_id"], name: "index_api_tokens_on_lead_provider_id"
  end

  create_table "application_states", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.bigint "lead_provider_id"
    t.enum "state", default: "active", null: false, enum_type: "application_statuses"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_application_states_on_application_id"
    t.index ["lead_provider_id"], name: "index_application_states_on_lead_provider_id"
  end

  create_table "applications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.bigint "lead_provider_id", null: false
    t.text "DEPRECATED_school_urn"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "ecf_id"
    t.enum "headteacher_status", enum_type: "headteacher_statuses"
    t.boolean "eligible_for_funding", default: false, null: false
    t.enum "funding_choice", enum_type: "funding_choices"
    t.text "ukprn"
    t.text "teacher_catchment"
    t.text "teacher_catchment_country"
    t.boolean "works_in_school"
    t.string "employer_name"
    t.string "employment_role"
    t.text "DEPRECATED_private_childcare_provider_urn"
    t.boolean "works_in_nursery"
    t.boolean "works_in_childcare"
    t.enum "kind_of_nursery", enum_type: "kind_of_nurseries"
    t.integer "DEPRECATED_cohort"
    t.boolean "targeted_delivery_funding_eligibility", default: false
    t.string "funding_eligiblity_status_code"
    t.jsonb "raw_application_data", default: {}
    t.text "work_setting"
    t.boolean "teacher_catchment_synced_to_ecf", default: false
    t.string "employment_type"
    t.string "DEPRECATED_itt_provider"
    t.boolean "lead_mentor", default: false
    t.boolean "primary_establishment", default: false
    t.integer "number_of_pupils", default: 0
    t.boolean "tsf_primary_eligibility", default: false
    t.boolean "tsf_primary_plus_eligibility", default: false
    t.enum "lead_provider_approval_status", enum_type: "lead_provider_approval_statuses"
    t.text "participant_outcome_state"
    t.bigint "school_id"
    t.bigint "private_childcare_provider_id"
    t.bigint "itt_provider_id"
    t.string "teacher_catchment_iso_country_code", limit: 3
    t.boolean "targeted_support_funding_eligibility", default: false
    t.string "notes"
    t.bigint "cohort_id"
    t.boolean "funded_place"
    t.enum "training_status", default: "active", null: false, enum_type: "application_statuses"
    t.bigint "schedule_id"
    t.string "referred_by_return_to_teaching_adviser"
    t.datetime "accepted_at"
    t.index ["cohort_id"], name: "index_applications_on_cohort_id"
    t.index ["course_id"], name: "index_applications_on_course_id"
    t.index ["itt_provider_id"], name: "index_applications_on_itt_provider_id"
    t.index ["lead_provider_id"], name: "index_applications_on_lead_provider_id"
    t.index ["private_childcare_provider_id"], name: "index_applications_on_private_childcare_provider_id"
    t.index ["schedule_id"], name: "index_applications_on_schedule_id"
    t.index ["school_id"], name: "index_applications_on_school_id"
    t.index ["user_id"], name: "index_applications_on_user_id"
  end

  create_table "closed_registration_users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cohorts", force: :cascade do |t|
    t.integer "start_year", null: false
    t.datetime "registration_start_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "funding_cap", default: false, null: false
    t.index ["start_year"], name: "index_cohorts_on_start_year", unique: true
  end

  create_table "course_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_course_groups_on_name", unique: true
  end

  create_table "courses", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "ecf_id"
    t.text "description"
    t.integer "position", default: 0
    t.boolean "display", default: true
    t.string "identifier"
    t.bigint "course_group_id"
    t.index ["course_group_id"], name: "index_courses_on_course_group_id"
    t.index ["identifier"], name: "index_courses_on_identifier", unique: true
  end

  create_table "data_migrations", force: :cascade do |t|
    t.string "model", null: false
    t.integer "processed_count", default: 0, null: false
    t.integer "failure_count", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_count"
  end

  create_table "declarations", force: :cascade do |t|
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "application_id", null: false
    t.bigint "superseded_by_id"
    t.bigint "lead_provider_id", null: false
    t.bigint "cohort_id", null: false
    t.enum "declaration_type", enum_type: "declaration_types"
    t.datetime "declaration_date", precision: nil
    t.enum "state", default: "submitted", null: false, enum_type: "declaration_states"
    t.enum "state_reason", enum_type: "declaration_state_reasons"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_declarations_on_application_id"
    t.index ["cohort_id"], name: "index_declarations_on_cohort_id"
    t.index ["ecf_id"], name: "index_declarations_on_ecf_id"
    t.index ["lead_provider_id"], name: "index_declarations_on_lead_provider_id"
    t.index ["superseded_by_id"], name: "index_declarations_on_superseded_by_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cron"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "ecf_sync_request_logs", force: :cascade do |t|
    t.integer "syncable_id", null: false
    t.string "syncable_type", null: false
    t.string "status", null: false
    t.string "sync_type", null: false
    t.jsonb "error_messages", default: []
    t.jsonb "response_body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["syncable_id", "syncable_type"], name: "index_ecf_sync_request_logs_on_syncable_id_and_syncable_type"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "get_an_identity_webhook_messages", force: :cascade do |t|
    t.jsonb "raw"
    t.jsonb "message"
    t.string "message_id"
    t.string "message_type"
    t.string "status", default: "pending"
    t.string "status_comment"
    t.datetime "sent_at", precision: nil
    t.datetime "processed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "itt_providers", force: :cascade do |t|
    t.text "legal_name"
    t.text "operating_name"
    t.datetime "removed_at", precision: nil
    t.boolean "approved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["legal_name"], name: "index_itt_providers_on_legal_name", unique: true
  end

  create_table "lead_providers", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "ecf_id"
    t.string "hint"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ukprn"], name: "index_local_authorities_on_ukprn"
  end

  create_table "participant_id_changes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "from_participant_id", null: false
    t.bigint "to_participant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_participant_id"], name: "index_participant_id_changes_on_from_participant_id"
    t.index ["to_participant_id"], name: "index_participant_id_changes_on_to_participant_id"
    t.index ["user_id"], name: "index_participant_id_changes_on_user_id"
  end

  create_table "participant_outcomes", force: :cascade do |t|
    t.enum "state", null: false, enum_type: "outcome_states"
    t.date "completion_date", null: false
    t.bigint "declaration_id", null: false
    t.boolean "qualified_teachers_api_request_successful"
    t.datetime "sent_to_qualified_teachers_api_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.index ["declaration_id", "created_at"], name: "index_participant_outcomes_on_declaration_id_and_created_at"
    t.index ["declaration_id"], name: "index_participant_outcomes_on_declaration_id"
    t.index ["ecf_id"], name: "index_participant_outcomes_on_ecf_id", unique: true
  end

  create_table "private_childcare_providers", force: :cascade do |t|
    t.text "provider_urn", null: false
    t.text "provider_name"
    t.text "registered_person_urn"
    t.text "registered_person_name"
    t.text "registration_date"
    t.text "provider_status"
    t.text "address_1"
    t.text "address_2"
    t.text "address_3"
    t.text "town"
    t.text "postcode"
    t.text "postcode_without_spaces"
    t.text "region"
    t.text "local_authority"
    t.text "ofsted_region"
    t.json "early_years_individual_registers", default: []
    t.boolean "provider_early_years_register_flag"
    t.boolean "provider_compulsory_childcare_register_flag"
    t.integer "places"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_urn"], name: "index_private_childcare_providers_on_provider_urn"
  end

  create_table "registration_interests", force: :cascade do |t|
    t.citext "email", null: false
    t.boolean "notified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_registration_interests_on_email", unique: true
  end

  create_table "reports", force: :cascade do |t|
    t.text "identifier", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "course_group_id", null: false
    t.bigint "cohort_id", null: false
    t.string "name", null: false
    t.string "identifier", null: false
    t.date "applies_from", null: false
    t.date "applies_to", null: false
    t.enum "allowed_declaration_types", default: ["started", "retained-1", "retained-2", "completed"], array: true, enum_type: "schedule_declaration_types"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id"], name: "index_schedules_on_cohort_id"
    t.index ["course_group_id"], name: "index_schedules_on_course_group_id"
    t.index ["identifier", "cohort_id"], name: "index_schedules_on_identifier_and_cohort_id", unique: true
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "establishment_type_code"
    t.text "establishment_type_name"
    t.boolean "high_pupil_premium", default: false, null: false
    t.text "postcode_without_spaces"
    t.integer "number_of_pupils"
    t.boolean "eyl_funding_eligible", default: false
    t.integer "phase_type", default: 0
    t.string "phase_name", default: "Not applicable"
    t.index "to_tsvector('english'::regconfig, COALESCE(name, ''::text))", name: "school_name_search_idx", using: :gin
    t.index ["urn"], name: "index_schools_on_urn"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", force: :cascade do |t|
    t.date "course_start_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "statement_items", force: :cascade do |t|
    t.bigint "statement_id", null: false
    t.enum "state", default: "eligible", null: false, enum_type: "statement_item_states"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "declaration_id"
    t.index ["declaration_id"], name: "index_statement_items_on_declaration_id"
    t.index ["statement_id"], name: "index_statement_items_on_statement_id"
  end

  create_table "statements", force: :cascade do |t|
    t.integer "month", null: false
    t.integer "year", null: false
    t.date "deadline_date"
    t.date "payment_date"
    t.boolean "output_fee", default: true, null: false
    t.bigint "cohort_id", null: false
    t.bigint "lead_provider_id", null: false
    t.datetime "marked_as_paid_at"
    t.decimal "reconcile_amount", precision: 8, scale: 2
    t.enum "state", default: "open", null: false, enum_type: "statement_states"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.index ["cohort_id"], name: "index_statements_on_cohort_id"
    t.index ["ecf_id"], name: "index_statements_on_ecf_id", unique: true
    t.index ["lead_provider_id"], name: "index_statements_on_lead_provider_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "ecf_id"
    t.text "trn"
    t.text "full_name"
    t.date "date_of_birth"
    t.boolean "trn_verified", default: false, null: false
    t.boolean "active_alert", default: false
    t.text "national_insurance_number"
    t.boolean "trn_auto_verified", default: false
    t.string "provider"
    t.string "uid"
    t.jsonb "raw_tra_provider_data"
    t.string "feature_flag_id"
    t.boolean "get_an_identity_id_synced_to_ecf", default: false
    t.datetime "updated_from_tra_at", precision: nil
    t.string "trn_lookup_status"
    t.boolean "notify_user_for_future_reg", default: false
    t.integer "email_updates_status", default: 0
    t.string "email_updates_unsubscribe_key"
    t.index ["ecf_id"], name: "index_users_on_ecf_id"
    t.index ["email"], name: "index_users_on_email"
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "api_tokens", "lead_providers"
  add_foreign_key "application_states", "applications"
  add_foreign_key "application_states", "lead_providers"
  add_foreign_key "applications", "cohorts"
  add_foreign_key "applications", "courses"
  add_foreign_key "applications", "itt_providers"
  add_foreign_key "applications", "lead_providers"
  add_foreign_key "applications", "private_childcare_providers"
  add_foreign_key "applications", "schedules"
  add_foreign_key "applications", "schools"
  add_foreign_key "applications", "users"
  add_foreign_key "courses", "course_groups"
  add_foreign_key "declarations", "applications"
  add_foreign_key "declarations", "cohorts"
  add_foreign_key "declarations", "declarations", column: "superseded_by_id"
  add_foreign_key "declarations", "lead_providers"
  add_foreign_key "participant_id_changes", "users"
  add_foreign_key "participant_id_changes", "users", column: "from_participant_id"
  add_foreign_key "participant_id_changes", "users", column: "to_participant_id"
  add_foreign_key "participant_outcomes", "declarations"
  add_foreign_key "schedules", "cohorts"
  add_foreign_key "schedules", "course_groups"
  add_foreign_key "statement_items", "declarations"
  add_foreign_key "statement_items", "statements"
  add_foreign_key "statements", "cohorts"
  add_foreign_key "statements", "lead_providers"
end
