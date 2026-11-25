require "test_helper"

class ProfileTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "perfil@example.test", password: "senha-bem-longa")
    @other = User.create!(email: "outra-conta@example.test", password: "outra-senha-longa")
  end

  test "guests cannot view or update a profile" do
    get "/perfil"
    assert_redirected_to new_session_path

    patch "/perfil", params: { profile: { display_name: "Visitante" } }
    assert_redirected_to new_session_path
  end

  test "existing accounts can open their empty profile from the main navigation" do
    login
    get root_path
    assert_select 'nav a[href="/exames"] + a[href="/perfil"]', text: "Perfil"

    get "/perfil"
    assert_response :success
    assert_select 'nav a[aria-current="page"]', text: "Perfil", count: 1
    assert_select 'form[action="/perfil"]' do
      %w[display_name birth_date weight_kg height_cm].each do |field|
        assert_select "input[name='profile[#{field}]']" do |inputs|
          assert_empty inputs.first["value"].to_s
          assert_nil inputs.first["required"]
        end
      end
    end
  end

  test "the profile saves both decimal separators and replaces or clears optional values" do
    login
    patch "/perfil", params: { profile: {
      display_name: "  Ana Martins  ", birth_date: "1995-06-10", weight_kg: "64,75", height_cm: "169.5"
    } }
    assert_response :see_other
    assert_redirected_to "/perfil"
    assert_equal [ "Ana Martins", Date.new(1995, 6, 10), 64.75, 169.5 ], @user.reload.values_at(:display_name, :birth_date, :weight_kg, :height_cm)

    follow_redirect!
    assert_select '[role="status"]', text: "Perfil atualizado."
    assert_select 'input[name="profile[display_name]"][value="Ana Martins"]'
    assert_select 'input[name="profile[birth_date]"][value="1995-06-10"]'
    assert_select 'input[name="profile[weight_kg]"][value="64,75"]'
    assert_select 'input[name="profile[height_cm]"][value="169,5"]'

    patch "/perfil", params: { profile: { display_name: " ", birth_date: "", weight_kg: "65.25", height_cm: "" } }
    assert_response :see_other
    assert_equal [ nil, nil, 65.25, nil ], @user.reload.values_at(:display_name, :birth_date, :weight_kg, :height_cm)

    patch "/perfil", params: { profile: { weight_kg: "" } }
    assert_response :see_other
    assert_nil @user.reload.weight_kg
  end

  test "profile reads and updates are scoped to the signed in account" do
    login
    @other.update!(display_name: "Nome privado", weight_kg: 87)

    get "/perfil", params: { id: @other.id }
    assert_response :success
    refute_includes response.body, "Nome privado"

    patch "/perfil", params: {
      id: @other.id, profile: { id: @other.id, user_id: @other.id, display_name: "Meu nome", email: "alterado@example.test", password: "nova-senha-longa" }
    }
    assert_response :see_other
    assert_equal "Meu nome", @user.reload.display_name
    assert_equal "perfil@example.test", @user.email
    assert @user.authenticate("senha-bem-longa")
    assert_equal [ "Nome privado", 87 ], @other.reload.values_at(:display_name, :weight_kg)
  end

  test "invalid measures leave the stored profile intact and keep the submitted values in the form" do
    login
    @user.update!(display_name: "Nome salvo", weight_kg: 70, height_cm: 170)

    [ "0", "-1", "72kg", "1e400" ].each do |weight|
      patch "/perfil", params: { profile: { display_name: "Novo nome", weight_kg: weight, height_cm: "169,5" } }
      assert_response :unprocessable_entity
      assert_select 'nav a[aria-current="page"]', text: "Perfil", count: 1
      assert_select '[role="alert"]', /Peso atual/
      assert_select 'input[name="profile[weight_kg]"][aria-invalid="true"][value=?]', weight
      assert_select 'input[name="profile[height_cm]"][value="169,5"]'
      assert_select 'input[name="profile[display_name]"][value="Novo nome"]'
    end

    patch "/perfil", params: { profile: { height_cm: "1,7,5" } }
    assert_response :unprocessable_entity
    assert_select '[role="alert"]', /Altura/
    assert_equal [ "Nome salvo", 70, 170 ], @user.reload.values_at(:display_name, :weight_kg, :height_cm)
  end

  test "birth date must exist on the calendar and cannot be after the local day" do
    login
    travel_to Time.zone.local(2026, 11, 25, 23, 30) do
      patch "/perfil", params: { profile: { birth_date: "2026-11-25" } }
      assert_response :see_other

      [ "2026-11-26", "2026-02-30", "inválida" ].each do |date|
        patch "/perfil", params: { profile: { birth_date: date } }
        assert_response :unprocessable_entity
        assert_select '[role="alert"]', /Data de nascimento/
        assert_select 'input[name="profile[birth_date]"][aria-invalid="true"][max="2026-11-25"]'
        assert_equal Date.new(2026, 11, 25), @user.reload.birth_date
      end
    end
  end

  test "profile data is hidden from request and SQL logs" do
    login
    output = StringIO.new
    capture = ActiveSupport::Logger.new(output, level: Logger::DEBUG)
    Rails.logger.broadcast_to(capture)

    User.with_connection do |connection|
      connection.unprepared_statement do
        patch "/perfil", params: { profile: {
          display_name: "Nome reservado do perfil", birth_date: "1992-04-17", weight_kg: "82,375", height_cm: "177,625"
        } }
      end
    end
    assert_response :see_other
    assert_includes output.string, "Processing by ProfilesController#update"
    assert_includes output.string, '"display_name" => "[FILTERED]"'
    [ "Nome reservado do perfil", "1992-04-17", "82,375", "82.375", "177,625", "177.625" ].each do |private_value|
      refute_includes output.string, private_value
    end
  ensure
    Rails.logger.stop_broadcasting_to(capture) if capture
  end

  private

  def login
    post session_path, params: { email: @user.email, password: "senha-bem-longa" }
    assert_redirected_to root_path
  end
end
