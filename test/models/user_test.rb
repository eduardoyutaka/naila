require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "password_reset_token generates a signed token" do
    user = users(:operator)
    token = user.password_reset_token
    assert_not_nil token
    assert_kind_of String, token
  end

  test "find_by_password_reset_token returns user for valid token" do
    user = users(:operator)
    token = user.password_reset_token
    assert_equal user, User.find_by_password_reset_token(token)
  end

  test "find_by_password_reset_token returns nil for unknown token" do
    assert_nil User.find_by_password_reset_token("invalid-token")
  end

  test "find_by_password_reset_token returns nil after password changes" do
    user = users(:operator)
    token = user.password_reset_token
    user.update!(password: "newpassword456", password_confirmation: "newpassword456")
    assert_nil User.find_by_password_reset_token(token)
  end
end
