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

ActiveRecord::Schema[8.0].define(version: 2026_02_21_144929) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

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

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "author"
    t.string "file_path"
    t.integer "chunks_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "daily_metrics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date_logged"
    t.integer "calories_consumed"
    t.integer "protein_consumed"
    t.integer "steps"
    t.float "weight"
    t.text "raw_message_content"
    t.boolean "compliant"
    t.jsonb "ai_parsed_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_dietary_plan_id"
    t.boolean "on_target", default: false
    t.boolean "workout_completed", default: false
    t.index ["user_dietary_plan_id"], name: "index_daily_metrics_on_user_dietary_plan_id"
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
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name"
    t.string "video_link"
    t.string "muscle_group"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "routine_exercises", force: :cascade do |t|
    t.bigint "routine_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "sets"
    t.string "reps"
    t.integer "rest_seconds"
    t.integer "order_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "day_number"
    t.string "day_name"
    t.string "load"
    t.string "warmup_sets"
    t.string "early_rpe"
    t.string "last_rpe"
    t.string "time_estimate"
    t.string "intensity_technique"
    t.string "sub_option_one"
    t.string "sub_option_two"
    t.index ["exercise_id"], name: "index_routine_exercises_on_exercise_id"
    t.index ["routine_id"], name: "index_routine_exercises_on_routine_id"
  end

  create_table "routines", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id"
    t.boolean "is_template", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "program_id"
    t.integer "duration_weeks"
    t.index ["program_id"], name: "index_routines_on_program_id"
    t.index ["user_id"], name: "index_routines_on_user_id"
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
    t.index ["dietary_plan_id"], name: "index_user_dietary_plans_on_dietary_plan_id"
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
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "ai_conversations", "programs"
  add_foreign_key "ai_conversations", "users"
  add_foreign_key "ai_messages", "ai_conversations"
  add_foreign_key "book_chunks", "books"
  add_foreign_key "coach_alerts", "users"
  add_foreign_key "daily_metrics", "user_dietary_plans"
  add_foreign_key "daily_metrics", "users"
  add_foreign_key "programs", "users"
  add_foreign_key "routine_exercises", "exercises"
  add_foreign_key "routine_exercises", "routines"
  add_foreign_key "routines", "programs"
  add_foreign_key "routines", "users"
  add_foreign_key "user_dietary_plans", "dietary_plans"
  add_foreign_key "user_dietary_plans", "users"
end
