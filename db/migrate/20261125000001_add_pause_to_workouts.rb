class AddPauseToWorkouts < ActiveRecord::Migration[8.1]
  def change
    add_column :workouts, :paused_at, :datetime
    add_column :workouts, :paused_duration_ms, :bigint, default: 0, null: false
  end
end
