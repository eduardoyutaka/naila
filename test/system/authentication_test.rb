require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "unauthenticated user is redirected to login" do
    visit admin_root_path
    assert_current_path login_path
  end

  test "user can sign in with valid credentials" do
    sign_in users(:admin)
    assert_text users(:admin).name
  end

  test "user cannot sign in with wrong password" do
    visit login_path
    fill_in "Email", with: users(:admin).email_address
    fill_in "Senha", with: "wrongpassword"
    click_button "Entrar"

    assert_current_path login_path
  end

  test "user can sign out" do
    sign_in users(:admin)

    find("button[title='Sair']").click
    assert_current_path login_path
  end

  test "public pages are accessible without login" do
    visit root_path
    assert_current_path root_path
  end
end
