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

ActiveRecord::Schema[8.1].define(version: 2026_11_24_000000) do
  create_table "lab_results", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "indicator", null: false
    t.string "unit", null: false
    t.decimal "value", null: false
    t.date "measured_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_lab_results_on_user_id"
  end

  create_table "lifting_sets", force: :cascade do |t|
    t.integer "workout_id", null: false
    t.string "exercise", null: false
    t.integer "reps", null: false
    t.decimal "weight", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_id"], name: "index_lifting_sets_on_workout_id"
  end

  create_table "sleep_entries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "day", null: false
    t.integer "minutes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "day"], name: "index_sleep_entries_on_user_id_and_day", unique: true
    t.index ["user_id"], name: "index_sleep_entries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "water_entries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "milliliters", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_water_entries_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_water_entries_on_user_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "kind", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.decimal "distance_km"
    t.integer "run_duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_workouts_on_user_id"
    t.index ["user_id"], name: "one_open_workout_per_user", unique: true, where: "finished_at IS NULL"
  end

  add_foreign_key "lab_results", "users"
  add_foreign_key "lifting_sets", "workouts"
  add_foreign_key "sleep_entries", "users"
  add_foreign_key "water_entries", "users"
  add_foreign_key "workouts", "users"
end
