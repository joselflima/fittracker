class WorkoutsController < ApplicationController
  before_action :load_workout, only: %i[show finish]

  def index
    @workouts = current_user.workouts.order(started_at: :desc)
    @active = current_user.workouts.find_by(finished_at: nil)
  end

  def create
    workout = current_user.with_lock do
      current_user.workouts.find_by(finished_at: nil) ||
        current_user.workouts.create!(kind: params[:kind], started_at: Time.current)
    end
    redirect_to workout_path(workout), status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to workouts_path, alert: "Escolha musculação ou corrida.", status: :see_other
  end

  def show
  end

  def finish
    @workout.finish!(params.permit(:distance_km, :run_minutes, :run_seconds).to_h)
    redirect_to workout_path(@workout), notice: "Treino finalizado.", status: :see_other
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = @workout.running? ? "Confira a distância e o tempo de corrida." : "Adicione uma série antes de finalizar."
    @workout.reload
    render :show, status: :unprocessable_entity
  end

  private

  def load_workout
    @workout = current_user.workouts.find(params[:id])
  end
end
