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

ActiveRecord::Schema[8.0].define(version: 2026_06_05_000434) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_conversations", force: :cascade do |t|
    t.bigint "user_id"
    t.string "title"
    t.text "objectives"
    t.string "status", default: "active"
    t.jsonb "generated_data"
    t.bigint "program_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_ai_conversations_on_program_id"
    t.index ["user_id"], name: "index_ai_conversations_on_user_id"
  end

  create_table "ai_messages", force: :cascade do |t|
    t.bigint "ai_conversation_id", null: false
    t.string "role", null: false
    t.text "content", null: false
    t.jsonb "structured_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_conversation_id"], name: "index_ai_messages_on_ai_conversation_id"
  end

  create_table "book_chunks", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.text "content", null: false
    t.integer "page_number"
    t.integer "chunk_index"
    t.vector "embedding", limit: 768
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_book_chunks_on_book_id"
    t.index ["embedding"], name: "index_book_chunks_on_embedding", opclass: :vector_cosine_ops, using: :hnsw
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "scheduled_at", null: false
    t.string "google_event_id"
    t.string "meet_link"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_at"], name: "index_bookings_on_scheduled_at"
    t.index ["user_id"], name: "index_bookings_on_user_id", unique: true
  end

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "author"
    t.string "file_path"
    t.integer "chunks_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ingestion_status", default: 0, null: false
  end

  create_table "coach_alerts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "category", null: false
    t.text "message"
    t.integer "status", default: 0
    t.text "action_taken"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_coach_alerts_on_user_id"
  end

  create_table "coach_schedules", force: :cascade do |t|
    t.integer "day_of_week", null: false
    t.integer "start_hour", default: 9, null: false
    t.integer "end_hour", default: 18, null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day_of_week"], name: "index_coach_schedules_on_day_of_week", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "last_message_at"
    t.datetime "read_by_coach_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["user_id"], name: "index_conversations_on_user_id", unique: true
  end

  create_table "daily_metrics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date_logged"
    t.integer "calories_consumed"
    t.integer "protein_consumed"
    t.float "weight"
    t.text "raw_message_content"
    t.boolean "compliant"
    t.jsonb "ai_parsed_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_dietary_plan_id"
    t.boolean "on_target", default: false
    t.boolean "workout_completed", default: false
    t.integer "fats"
    t.integer "carbs"
    t.index ["user_dietary_plan_id"], name: "index_daily_metrics_on_user_dietary_plan_id"
    t.index ["user_id", "date_logged"], name: "index_daily_metrics_on_user_id_and_date_logged"
    t.index ["user_id"], name: "index_daily_metrics_on_user_id"
  end

  create_table "dietary_plans", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "calories_target"
    t.integer "protein_target"
    t.text "notes"
    t.integer "fats_target"
    t.integer "carbs_target"
  end

  create_table "exercise_logs", force: :cascade do |t|
    t.bigint "workout_exercise_id", null: false
    t.jsonb "actual_sets"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "training_session_id", null: false
    t.index ["training_session_id", "workout_exercise_id"], name: "index_exercise_logs_unique_per_session", unique: true
    t.index ["training_session_id"], name: "index_exercise_logs_on_training_session_id"
    t.index ["workout_exercise_id"], name: "index_exercise_logs_on_workout_exercise_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name"
    t.string "video_link"
    t.string "muscle_group"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_exercises_on_name_unique", unique: true
  end

  create_table "google_credentials", force: :cascade do |t|
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "sender_type"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "conversation_id", null: false
    t.datetime "discarded_at"
    t.datetime "read_at"
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["discarded_at"], name: "index_messages_on_discarded_at"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "notification_type"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_notifications_on_conversation_id"
  end

  create_table "onboarding_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "gender"
    t.integer "age"
    t.string "weight"
    t.string "height"
    t.string "instagram"
    t.jsonb "goals"
    t.integer "experience_level"
    t.text "best_lifts"
    t.string "commitment_level"
    t.string "training_frequency"
    t.text "injuries"
    t.string "plays_sports"
    t.string "sport_details"
    t.string "time_per_session"
    t.string "diet_quality"
    t.string "activity_level"
    t.string "sleep_hours"
    t.string "social_media_consent"
    t.string "referral_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
    t.string "training_years"
    t.string "goals_other"
    t.string "referral_source_other"
    t.index ["user_id"], name: "index_onboarding_profiles_on_user_id"
  end

  create_table "phase_routines", force: :cascade do |t|
    t.bigint "phase_id", null: false
    t.bigint "routine_id", null: false
    t.integer "order_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id"], name: "index_phase_routines_on_phase_id"
    t.index ["routine_id"], name: "index_phase_routines_on_routine_id"
  end

  create_table "phases", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.string "name"
    t.text "description"
    t.integer "order_index"
    t.integer "duration_weeks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_phases_on_program_id"
  end

  create_table "programs", force: :cascade do |t|
    t.string "name"
    t.integer "duration_weeks"
    t.text "description"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_sheet_link"
    t.datetime "last_synced_at"
    t.index ["user_id"], name: "index_programs_on_user_id"
  end

  create_table "progress_photos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "note"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_progress_photos_on_user_id"
  end

  create_table "promo_conversions", force: :cascade do |t|
    t.bigint "promo_link_id", null: false
    t.bigint "referred_user_id", null: false
    t.bigint "subscription_id", null: false
    t.string "plan_tier", null: false
    t.string "currency", null: false
    t.integer "full_price_cents", null: false
    t.integer "paid_amount_cents", null: false
    t.integer "promoter_earnings_cents", null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["promo_link_id"], name: "index_promo_conversions_on_promo_link_id"
    t.index ["referred_user_id"], name: "index_promo_conversions_on_referred_user_id", unique: true
    t.index ["subscription_id"], name: "index_promo_conversions_on_subscription_id"
  end

  create_table "promo_links", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "code", null: false
    t.string "label", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_promo_links_on_code", unique: true
    t.index ["user_id"], name: "index_promo_links_on_user_id"
  end

  create_table "routines", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id"
    t.boolean "is_template", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration_weeks"
    t.index ["user_id"], name: "index_routines_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "processor", null: false
    t.integer "plan_tier", null: false
    t.integer "status", default: 0, null: false
    t.string "external_id"
    t.string "external_customer_id"
    t.string "external_plan_id"
    t.string "currency", default: "USD"
    t.integer "amount_cents"
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "billing_type", default: 0, null: false
    t.integer "frequency", default: 0, null: false
    t.datetime "access_expires_at"
    t.datetime "reminded_at"
    t.datetime "past_due_since"
    t.string "mp_preference_id"
    t.bigint "promo_link_id"
    t.index ["mp_preference_id"], name: "index_subscriptions_on_mp_preference_id", unique: true, where: "(mp_preference_id IS NOT NULL)"
    t.index ["processor"], name: "index_subscriptions_on_processor"
    t.index ["promo_link_id"], name: "index_subscriptions_on_promo_link_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "training_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "program_id", null: false
    t.bigint "phase_id", null: false
    t.bigint "routine_id", null: false
    t.bigint "workout_id", null: false
    t.integer "cycle_number", null: false
    t.integer "session_number", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "skipped_at"
    t.string "skip_reason"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id"], name: "index_training_sessions_on_phase_id"
    t.index ["program_id"], name: "index_training_sessions_on_program_id"
    t.index ["user_id", "session_number"], name: "index_training_sessions_on_user_id_and_session_number"
    t.index ["user_id", "status"], name: "index_training_sessions_on_user_id_and_status"
    t.index ["workout_id"], name: "index_training_sessions_on_workout_id"
  end

  create_table "user_dietary_plans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "calories_target"
    t.integer "protein_target"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "dietary_plan_id"
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: true
    t.bigint "phase_id"
    t.integer "fats_target"
    t.integer "carbs_target"
    t.index ["dietary_plan_id"], name: "index_user_dietary_plans_on_dietary_plan_id"
    t.index ["phase_id"], name: "index_user_dietary_plans_on_phase_id"
    t.index ["user_id"], name: "index_user_dietary_plans_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.integer "status", default: 0
    t.integer "plan_tier"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category"
    t.integer "workout_compliance_score"
    t.integer "diet_adherence_score"
    t.string "auth_token"
    t.string "google_uid"
    t.string "provider", default: "email", null: false
    t.string "fcm_token"
    t.integer "access_status", default: 0, null: false
    t.string "payment_link_token"
    t.datetime "payment_link_expires_at"
    t.integer "admin_role"
    t.boolean "promoter", default: false, null: false
    t.index ["auth_token"], name: "index_users_on_auth_token", unique: true
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true, where: "(google_uid IS NOT NULL)"
    t.index ["payment_link_token"], name: "index_users_on_payment_link_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workout_exercises", force: :cascade do |t|
    t.bigint "exercise_id", null: false
    t.integer "sets"
    t.string "reps"
    t.integer "rest_seconds"
    t.integer "order_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "load"
    t.string "warmup_sets"
    t.string "early_rpe"
    t.string "last_rpe"
    t.string "time_estimate"
    t.string "intensity_technique"
    t.string "sub_option_one"
    t.string "sub_option_two"
    t.bigint "workout_id", null: false
    t.index ["exercise_id"], name: "index_workout_exercises_on_exercise_id"
    t.index ["workout_id"], name: "index_workout_exercises_on_workout_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "day_number"
    t.integer "order_index"
    t.bigint "routine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["routine_id"], name: "index_workouts_on_routine_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_conversations", "programs"
  add_foreign_key "ai_conversations", "users"
  add_foreign_key "ai_messages", "ai_conversations"
  add_foreign_key "book_chunks", "books"
  add_foreign_key "bookings", "users"
  add_foreign_key "coach_alerts", "users"
  add_foreign_key "conversations", "users"
  add_foreign_key "daily_metrics", "user_dietary_plans"
  add_foreign_key "daily_metrics", "users"
  add_foreign_key "exercise_logs", "training_sessions"
  add_foreign_key "exercise_logs", "workout_exercises"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "conversations"
  add_foreign_key "onboarding_profiles", "users"
  add_foreign_key "phase_routines", "phases"
  add_foreign_key "phase_routines", "routines"
  add_foreign_key "phases", "programs"
  add_foreign_key "programs", "users"
  add_foreign_key "progress_photos", "users"
  add_foreign_key "promo_conversions", "promo_links"
  add_foreign_key "promo_conversions", "subscriptions"
  add_foreign_key "promo_conversions", "users", column: "referred_user_id"
  add_foreign_key "promo_links", "users"
  add_foreign_key "routines", "users"
  add_foreign_key "subscriptions", "promo_links"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "training_sessions", "phases"
  add_foreign_key "training_sessions", "programs"
  add_foreign_key "training_sessions", "routines"
  add_foreign_key "training_sessions", "users"
  add_foreign_key "training_sessions", "workouts"
  add_foreign_key "user_dietary_plans", "dietary_plans"
  add_foreign_key "user_dietary_plans", "phases"
  add_foreign_key "user_dietary_plans", "users"
  add_foreign_key "workout_exercises", "exercises"
  add_foreign_key "workout_exercises", "workouts"
  add_foreign_key "workouts", "routines"
end
