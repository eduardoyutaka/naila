require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  private

  def sign_in(user, password: "password123")
    visit login_path
    fill_in "Email", with: user.email_address
    fill_in "Senha", with: password
    click_button "Entrar"
    assert_current_path admin_root_path
  end
end
