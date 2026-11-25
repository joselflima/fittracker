class DashboardController < ApplicationController
  def show
    @tab = params[:aba] == "hidratacao" ? "hidratacao" : "carga"
    if @tab == "hidratacao"
      @water_history = current_user.water_history
    else
      @history = current_user.exercise_history
    end
  end
end
