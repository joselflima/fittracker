class TodayController < ApplicationController
  def show
    @water = current_user.water_entries.where(created_at: Time.current.all_day).sum(:milliliters)
    @sleep = current_user.sleep_entries.find_by(day: Date.current)
    @workouts = current_user.workouts.where(started_at: Time.current.all_day).order(started_at: :desc)
    @active = current_user.workouts.find_by(finished_at: nil)
  end
end
