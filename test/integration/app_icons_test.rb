require "test_helper"

class AppIconsTest < ActionDispatch::IntegrationTest
  test "login and the private home advertise the same home screen icons" do
    get new_session_path
    assert_screen_links

    user = User.create!(email: "icon@example.test", password: "senha-bem-longa")
    post session_path, params: { email: user.email, password: "senha-bem-longa" }
    follow_redirect!
    assert_screen_links
  end

  test "launchers can fetch the manifest and its correctly sized PNG icons before login" do
    get "/manifest.webmanifest"
    assert_response :success
    assert_includes [ "application/manifest+json", "application/json" ], response.media_type
    manifest = JSON.parse(response.body)
    assert_equal "FitTracker", manifest.fetch("name")
    assert_equal "/", manifest.fetch("start_url")
    assert_equal "standalone", manifest.fetch("display")

    icons = manifest.fetch("icons")
    [ [ 192, "any" ], [ 512, "any" ], [ 512, "maskable" ] ].each do |size, purpose|
      entry = icons.find { |i| i["sizes"] == "#{size}x#{size}" && i.fetch("purpose", "any").split.include?(purpose) }
      assert entry, "Ícone #{size}px para #{purpose}"
      assert_png entry.fetch("src"), size
    end
    assert_png "/apple-touch-icon.png", 180
  end

  private

  def assert_screen_links
    assert_response :success
    assert_select 'head link[rel="manifest"][href="/manifest.webmanifest"]', count: 1
    assert_select 'head link[rel="apple-touch-icon"][href="/apple-touch-icon.png"][sizes="180x180"]', count: 1
  end

  def assert_png(path, size)
    get path
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal [ size, size ], response.body.byteslice(16, 8).unpack("NN")
  end
end
