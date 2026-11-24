class LiftingSetsController < ApplicationController
  def create
    workout = current_user.workouts.find(params[:workout_id])
    saved = workout.with_lock do
      next false if workout.finished_at? || workout.running?
      workout.lifting_sets.build(params.expect(lifting_set: [ :exercise, :reps, :weight ])).save
    end
    flash[saved ? :notice : :alert] = saved ? "Série registrada." : "Confira o exercício, as repetições e a carga do treino em andamento."
    redirect_to workout_path(workout), status: :see_other
  end
end
