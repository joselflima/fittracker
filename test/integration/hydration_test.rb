require "test_helper"

class HydrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "water@example.test", password: "senha-bem-longa")
    post session_path, params: { email: @user.email, password: "senha-bem-longa" }
  end

  test "estimate follows birthdays and current weight" do
    @user.weight_kg = 70
    { 17 => nil, 18 => 1750, 19 => 1550, 25 => 1500, 51 => 1300, 65 => 1400 }.each do |age, expected|
      @user.birth_date = Date.current - age.years
      assert_equal expected, @user.daily_fluid_ml if expected
      assert_nil @user.daily_fluid_ml unless expected
    end
    @user.update!(birth_date: 30.years.ago.to_date, weight_kg: 75.5)
    get root_path
    assert_select ".water p", text: /Estimativa de líquidos para hoje: 1.650 ml/
  end

  test "daily history follows local dates and account" do
    get root_path
    assert_select ".water a[href=?]", profile_path
    get dashboard_path
    assert_select "#hydration", count: 0
    assert_select "nav.subnav a[aria-current='page']", text: "Carga"
    get dashboard_path(aba: "hidratacao")
    assert_select ".mast nav a[aria-current='page']", text: "Evolução"
    assert_select "nav.subnav a[aria-current='page']", text: "Hidratação"
    assert_select "p", text: "Seu histórico começa com o primeiro registro de água"
    midnight = Time.zone.local(2026, 1, 5)
    [ [ midnight - 1.minute, 120 ], [ midnight, 230 ], [ midnight + 2.days, 400 ] ].each do |time, ml|
      @user.water_entries.create!(created_at: time, milliliters: ml)
    end
    User.create!(email: "other@example.test", password: "senha-bem-longa").water_entries.create!(created_at: midnight, milliliters: 800)
    travel_to(midnight + 1.minute) do
      post water_entries_path, params: { milliliters: 250 }
      follow_redirect!
      assert_select "#water-total", text: /480/
      get dashboard_path(aba: "hidratacao")
      assert_equal %w[120 480 400], css_select("#hydration tbody tr td:last-child").map(&:text)
      assert_select "article.exercise", count: 0
    end
  end
end
