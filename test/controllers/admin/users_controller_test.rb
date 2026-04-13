require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_users_path
    assert_response :success
  end

  test "index displays user names" do
    get admin_users_path
    assert_select "td", text: /Ana Silva/
    assert_select "td", text: /Bruno Costa/
  end

  # ── Filters ──

  test "index filters by role" do
    get admin_users_path(q: { role: "admin" })
    assert_response :success
    assert_select "td", text: /Ana Silva/
    assert_select "td", text: /Carla Souza/, count: 0
  end

  test "index filters by active status" do
    get admin_users_path(q: { active: "false" })
    assert_response :success
    assert_select "td", text: /Diego Lima/
    assert_select "td", text: /Ana Silva/, count: 0
  end

  test "index filters by search" do
    get admin_users_path(q: { search: "Bruno" })
    assert_response :success
    assert_select "td", text: /Bruno Costa/
    assert_select "td", text: /Ana Silva/, count: 0
  end

  test "index shows clear filters link when no results" do
    get admin_users_path(q: { search: "nonexistent" })
    assert_response :success
    assert_select "a", text: /Limpar filtros/
  end

  test "index shows empty state with no results" do
    get admin_users_path(q: { search: "nonexistent" })
    assert_select "div", text: /Nenhum usuário encontrado/
  end
end
