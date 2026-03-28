require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  # ── new ──

  test "new renders the forgot password form" do
    get new_password_reset_path
    assert_response :success
  end

  # ── create ──

  test "create with valid email redirects to login with generic notice" do
    post forgot_password_path, params: { email_address: users(:admin).email_address }
    assert_redirected_to login_path
    assert_match "instruções", flash[:notice]
  end

  test "create with unknown email redirects to login with same generic notice" do
    post forgot_password_path, params: { email_address: "unknown@example.com" }
    assert_redirected_to login_path
    assert_match "instruções", flash[:notice]
  end

  test "create with valid email enqueues mailer" do
    assert_enqueued_email_with PasswordResetMailer, :reset_instructions,
                               args: [ users(:admin) ] do
      post forgot_password_path, params: { email_address: users(:admin).email_address }
    end
  end

  test "create with unknown email does not enqueue mailer" do
    assert_no_enqueued_emails do
      post forgot_password_path, params: { email_address: "unknown@example.com" }
    end
  end

  # ── edit ──

  test "edit with valid token renders reset form" do
    token = users(:admin).password_reset_token
    get edit_password_reset_path(token)
    assert_response :success
  end

  test "edit with invalid token redirects to new with alert" do
    get edit_password_reset_path("bogus-token")
    assert_redirected_to new_password_reset_path
    assert_match "inválido", flash[:alert]
  end

  # ── update ──

  test "update with valid token and matching passwords changes password and redirects to login" do
    user = users(:admin)
    token = user.password_reset_token

    patch password_reset_path(token), params: {
      user: { password: "newsecurepass1", password_confirmation: "newsecurepass1" }
    }

    assert_redirected_to login_path
    assert_match "sucesso", flash[:notice]
    assert user.reload.authenticate("newsecurepass1")
  end

  test "update with valid token destroys all user sessions" do
    user = users(:admin)
    user.sessions.create!(token: SecureRandom.urlsafe_base64, ip_address: "127.0.0.1")
    token = user.password_reset_token

    assert_difference "user.sessions.count", -1 do
      patch password_reset_path(token), params: {
        user: { password: "newsecurepass1", password_confirmation: "newsecurepass1" }
      }
    end
  end

  test "update with invalid token redirects to new with alert" do
    patch password_reset_path("bogus-token"), params: {
      user: { password: "newsecurepass1", password_confirmation: "newsecurepass1" }
    }
    assert_redirected_to new_password_reset_path
    assert_match "inválido", flash[:alert]
  end

  test "update with mismatched passwords re-renders edit" do
    token = users(:admin).password_reset_token

    patch password_reset_path(token), params: {
      user: { password: "newsecurepass1", password_confirmation: "differentpass" }
    }

    assert_response :unprocessable_entity
  end

  test "used token cannot be reused after password change" do
    user = users(:admin)
    token = user.password_reset_token

    patch password_reset_path(token), params: {
      user: { password: "newsecurepass1", password_confirmation: "newsecurepass1" }
    }

    # Token is now invalid because password changed
    patch password_reset_path(token), params: {
      user: { password: "anotherpass1", password_confirmation: "anotherpass1" }
    }
    assert_redirected_to new_password_reset_path
  end
end
