require "test_helper"

class TrackingTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "atleta@example.test", password: "senha-bem-longa")
    @other = User.create!(email: "outro@example.test", password: "outra-senha-longa")
  end

  def login
    post session_path, params: { email: @user.email.upcase, password: "senha-bem-longa" }
    assert_redirected_to root_path
  end

  test "private pages require login and logout closes the session" do
    [ root_path, dashboard_path, lab_results_path, workouts_path ].each do |path|
      get path
      assert_redirected_to new_session_path
    end
    post session_path, params: { email: @user.email, password: "errada" }
    assert_response :unprocessable_entity
    login
    get root_path
    assert_response :success
    delete session_path
    get root_path
    assert_redirected_to new_session_path
  end

  test "home totals water and replaces sleep for the local day only" do
    login
    travel_to Time.zone.local(2026, 11, 20, 23, 55) do
      post water_entries_path, params: { milliliters: 700 }
      post sleep_entry_path, params: { hours: 6, minutes: 20 }
    end
    travel_to Time.zone.local(2026, 11, 21, 0, 5) do
      @other.water_entries.create!(milliliters: 950)
      [ 250, 300 ].each { |ml| post water_entries_path, params: { milliliters: ml } }
      post sleep_entry_path, params: { hours: 7, minutes: 30 }
      post sleep_entry_path, params: { hours: 8, minutes: 5 }
      assert_no_difference("WaterEntry.count") { post water_entries_path, params: { milliliters: -50 } }
      post sleep_entry_path, params: { hours: 7, minutes: 70 }
      get root_path
      assert_select "#water-total", /550/
      assert_select "#sleep-total", /8h 05min/
    end
  end

  test "strength session persists timer and individual sets until finished" do
    login
    post workouts_path, params: { kind: "strength" }
    workout = @user.workouts.sole
    assert_redirected_to workout_path(workout)
    assert_no_difference("Workout.count") { post workouts_path, params: { kind: "running" } }
    get workout_path(workout)
    assert_select "[data-controller='timer']"
    patch finish_workout_path(workout)
    assert_nil workout.reload.finished_at
    [ [ 10, 20 ], [ 8, 25 ] ].each do |reps, weight|
      post workout_lifting_sets_path(workout), params: { lifting_set: { exercise: " Supino ", reps: reps, weight: weight } }
    end
    assert_no_difference("LiftingSet.count") do
      post workout_lifting_sets_path(workout), params: { lifting_set: { exercise: "Supino", reps: 0, weight: 20 } }
    end
    travel 12.minutes do
      patch finish_workout_path(workout)
      assert_in_delta 720, workout.reload.elapsed_seconds, 1
    end
    assert_equal [ [ 10, 20 ], [ 8, 25 ] ], workout.lifting_sets.order(:id).pluck(:reps, :weight)
    assert_no_difference("LiftingSet.count") do
      post workout_lifting_sets_path(workout), params: { lifting_set: { exercise: "Outro", reps: 8, weight: 5 } }
    end
    get root_path
    assert_select "a[href=?]", workout_path(workout)
    get workout_path(workout)
    assert_select "[data-controller='timer']", count: 0
  end

  test "runs record distance and manual time or use elapsed time for pace" do
    login
    post workouts_path, params: { kind: "running" }
    workout = @user.workouts.sole
    patch finish_workout_path(workout), params: { distance_km: 0, run_minutes: 20 }
    assert_nil workout.reload.finished_at
    patch finish_workout_path(workout), params: { distance_km: "5.0", run_minutes: 27, run_seconds: 30 }
    assert_equal 1650, workout.reload.run_duration
    assert_equal 330, workout.pace_seconds
    get workout_path(workout)
    assert_select "main", /5:30.*\/km/
    post workouts_path, params: { kind: "running" }
    second = @user.workouts.last
    travel 10.minutes do
      patch finish_workout_path(second), params: { distance_km: "2" }
      assert_in_delta 300, second.reload.pace_seconds, 1
    end
  end

  test "dashboard plots daily personal maxima chronologically for each exercise" do
    login
    [ [ @user, 2.days.ago, "Supino", 20 ], [ @user, 2.days.ago, "supino", 25 ],
      [ @user, 1.day.ago, "Supino", 30 ], [ @other, 1.day.ago, "Supino", 90 ] ].each do |user, time, name, kg|
      workout = user.workouts.create!(kind: "strength", started_at: time, finished_at: time + 1.hour)
      workout.lifting_sets.create!(exercise: name, reps: 8, weight: kg)
    end
    get dashboard_path
    assert_response :success
    assert_select "article.exercise", count: 1
    assert_select "article.exercise tbody tr", count: 2
    assert_select "article.exercise tbody tr:first-child", /25 kg/
    assert_select "article.exercise tbody tr:last-child", /30 kg/
    assert_select "article.exercise svg[role=img]"
  end

  test "exam history groups indicators by unit and belongs to the signed in user" do
    login
    base = { indicator: "Ferritina", unit: "ng/mL", measured_on: Date.current }
    post lab_results_path, params: { lab_result: base.merge(value: "82.5") }
    post lab_results_path, params: { lab_result: base.merge(value: "60", measured_on: 1.month.ago.to_date) }
    @other.lab_results.create!(**base, value: 999)
    assert_no_difference("LabResult.count") do
      post lab_results_path, params: { lab_result: base.merge(value: "inválido") }
    end
    get lab_results_path
    assert_select "tbody tr", count: 2
    assert_select "tbody tr:first-child", /82,5/
    assert_select "tbody tr:last-child", /60/
    refute_includes response.body, "999"
  end

  test "foreign workouts cannot be opened modified or finished" do
    login
    workout = @other.workouts.create!(kind: "strength", started_at: Time.current)
    get workout_path(workout)
    assert_response :not_found
    post workout_lifting_sets_path(workout), params: { lifting_set: { exercise: "A", reps: 1, weight: 1 } }
    assert_response :not_found
    patch finish_workout_path(workout)
    assert_response :not_found
    assert_nil workout.reload.finished_at
  end
end
