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

  # ── Filter Scopes ──

  test "by_role scope filters by role" do
    admins = User.by_role("admin")
    assert_includes admins, users(:admin)
    assert_not_includes admins, users(:operator)
  end

  test "by_active scope filters by active flag" do
    active = User.by_active(true)
    assert_includes active, users(:admin)
    assert_not_includes active, users(:inactive)
  end

  test "search_by_name scope filters by name with ILIKE" do
    results = User.search_by_name("ana")
    assert_includes results, users(:admin)
    assert_not_includes results, users(:operator)
  end

  test "search_by_name scope returns all when term is blank" do
    assert_equal User.count, User.search_by_name("").count
    assert_equal User.count, User.search_by_name(nil).count
  end
end
