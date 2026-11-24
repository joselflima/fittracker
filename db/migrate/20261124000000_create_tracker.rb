class CreateTracker < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.timestamps
    end

    create_table :water_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :milliliters, null: false
      t.timestamps
    end
    add_index :water_entries, [ :user_id, :created_at ]

    create_table :sleep_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :day, null: false
      t.integer :minutes, null: false
      t.timestamps
    end
    add_index :sleep_entries, [ :user_id, :day ], unique: true

    create_table :workouts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.decimal :distance_km
      t.integer :run_duration
      t.timestamps
    end
    add_index :workouts, :user_id, unique: true, where: "finished_at IS NULL", name: "one_open_workout_per_user"

    create_table :lifting_sets do |t|
      t.references :workout, null: false, foreign_key: true
      t.string :exercise, null: false
      t.integer :reps, null: false
      t.decimal :weight, null: false
      t.timestamps
    end

    create_table :lab_results do |t|
      t.references :user, null: false, foreign_key: true
      t.string :indicator, null: false
      t.string :unit, null: false
      t.decimal :value, null: false
      t.date :measured_on, null: false
      t.timestamps
    end
  end
end
