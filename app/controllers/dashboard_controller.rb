class DashboardController < ApplicationController
  def show
    @history = current_user.exercise_history
  end
end
