require "test_helper"

class WorkoutControlsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "controle@example.test", password: "senha-bem-longa")
    post session_path, params: { email: @user.email, password: "senha-bem-longa" }
  end

  test "pause state is available immediately after updating a workout" do
    workout = start_workout("strength")
    refute workout.paused?

    workout.pause!
    assert workout.paused?
    assert workout.reload.paused?

    workout.resume!
    refute workout.paused?
  end

  test "multiple pauses persist and only active running time contributes to pace" do
    freeze_time
    workout = start_workout("running")
    travel 2.minutes
    patch "#{workout_path(workout)}/pause", headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_select "turbo-stream[action=replace]", /Continuar treino/
    travel 3.minutes
    patch "#{workout_path(workout)}/pause"
    get workout_path(workout)
    assert_select ".digits", "2:00"
    assert_select "[data-controller=timer]", count: 0
    [ workouts_path, root_path ].each do |path|
      get path
      assert_select "main", /Pausado/
    end
    assert_no_difference("Workout.count") { post workouts_path, params: { kind: "strength" } }
    patch "#{workout_path(workout)}/resume"
    travel 1.minute
    patch "#{workout_path(workout)}/resume"
    patch "#{workout_path(workout)}/pause"
    travel 4.minutes
    patch finish_workout_path(workout), params: { distance_km: "1" }
    assert_equal 180, workout.reload.elapsed_seconds
    assert_equal 180, workout.run_duration
    assert_equal 180, workout.pace_seconds
  end

  test "strength sets and finish remain available during pause" do
    workout = start_workout("strength")
    patch "#{workout_path(workout)}/pause"
    assert_difference("LiftingSet.count", 1) { add_set(workout) }
    patch finish_workout_path(workout)
    assert workout.reload.finished_at?
    get workout_path(workout)
    assert_select "button", text: /Pausar treino|Continuar treino|Cancelar treino/, count: 0
  end

  test "cancel removes a paused workout and its sets and frees the open slot" do
    workout = start_workout("strength")
    add_set(workout)
    patch "#{workout_path(workout)}/pause"
    get workout_path(workout)
    assert_select "form[data-turbo-confirm]", /Cancelar treino/
    assert_difference([ "Workout.count", "LiftingSet.count" ], -1) do
      delete workout_path(workout)
    end
    assert_redirected_to workouts_path
    follow_redirect!
    assert_select "button", "Iniciar musculação"
    assert_select "a[href=?]", workout_path(workout), count: 0
    start_workout("running")
  end

  test "finished or foreign sessions are protected from the new actions" do
    workout = start_workout("running")
    patch "#{workout_path(workout)}/pause"
    patch finish_workout_path(workout), params: { distance_km: 1, run_minutes: 5 }
    assert_equal 300, workout.reload.run_duration
    original = workout.reload.attributes
    %w[pause resume].each do |action|
      patch "#{workout_path(workout)}/#{action}"
      assert_redirected_to workout_path(workout)
    end
    delete workout_path(workout)
    assert_redirected_to workout_path(workout)
    assert_equal original, workout.reload.attributes

    other = User.create!(email: "fora@example.test", password: "outra-senha-longa")
    foreign = other.workouts.create!(kind: "strength", started_at: Time.current)
    %w[pause resume].each do |action|
      patch "#{workout_path(foreign)}/#{action}"
      assert_response :not_found
    end
    delete workout_path(foreign)
    assert_response :not_found
    assert foreign.reload
  end

  private

  def start_workout(kind)
    post workouts_path, params: { kind: kind }
    workout = @user.workouts.find_by!(finished_at: nil)
    assert_redirected_to workout_path(workout)
    workout
  end

  def add_set(workout)
    post workout_lifting_sets_path(workout), params: { lifting_set: { exercise: "Supino", reps: 8, weight: 20 } }
  end
end
