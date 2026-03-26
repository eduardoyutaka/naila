require "application_system_test_case"

class AdminRoleAccessTest < ApplicationSystemTestCase
  # ── Admin: full access ──

  test "admin can access user management" do
    sign_in users(:admin)
    visit admin_users_path

    assert_text "Usuários"
    assert_text "Novo Usuário"
  end

  test "admin can create a new user" do
    sign_in users(:admin)
    visit new_admin_user_path

    fill_in "Nome", with: "Novo Usuário"
    fill_in "Email", with: "novo@naila.test"
    select "Operador", from: "Cargo"
    fill_in "Senha", with: "senha12345"
    fill_in "Confirmar Senha", with: "senha12345"
    click_button "Criar Usuário"

    assert_text "Usuário criado com sucesso"
  end

  test "admin can edit another user" do
    sign_in users(:admin)
    visit edit_admin_user_path(users(:operator))

    fill_in "Nome", with: "Carla Atualizada"
    click_button "Salvar Alterações"

    assert_text "Usuário atualizado"
  end

  test "admin can delete another user" do
    sign_in users(:admin)
    visit admin_users_path

    user_to_delete = users(:operator)
    row = find("tr", text: user_to_delete.name)
    accept_confirm { row.find("button[title='Remover']").click }

    assert_text "Usuário removido"
  end

  test "admin can access dashboard" do
    sign_in users(:admin)
    visit admin_root_path

    assert_current_path admin_root_path
  end

  test "admin can access sensor stations" do
    sign_in users(:admin)
    visit admin_sensor_stations_path

    assert_current_path admin_sensor_stations_path
  end

  test "admin can access river basins" do
    sign_in users(:admin)
    visit admin_river_basins_path

    assert_current_path admin_river_basins_path
  end

  # ── Coordinator: can manage alerts but not users ──

  test "coordinator can access dashboard" do
    sign_in users(:coordinator)
    visit admin_root_path

    assert_current_path admin_root_path
  end

  test "coordinator cannot access user management" do
    sign_in users(:coordinator)
    visit admin_users_path

    assert_text "Voce nao tem permissao"
    assert_current_path admin_root_path
  end

  test "coordinator cannot create users" do
    sign_in users(:coordinator)
    visit new_admin_user_path

    assert_text "Voce nao tem permissao"
    assert_current_path admin_root_path
  end

  test "coordinator cannot edit users" do
    sign_in users(:coordinator)
    visit edit_admin_user_path(users(:operator))

    assert_text "Voce nao tem permissao"
    assert_current_path admin_root_path
  end

  test "coordinator can access sensor stations" do
    sign_in users(:coordinator)
    visit admin_sensor_stations_path

    assert_current_path admin_sensor_stations_path
  end

  test "coordinator can access river basins" do
    sign_in users(:coordinator)
    visit admin_river_basins_path

    assert_current_path admin_river_basins_path
  end

  # ── Operator: read-only access ──

  test "operator can access dashboard" do
    sign_in users(:operator)
    visit admin_root_path

    assert_current_path admin_root_path
  end

  test "operator cannot access user management" do
    sign_in users(:operator)
    visit admin_users_path

    assert_text "Voce nao tem permissao"
    assert_current_path admin_root_path
  end

  test "operator cannot create users" do
    sign_in users(:operator)
    visit new_admin_user_path

    assert_text "Voce nao tem permissao"
    assert_current_path admin_root_path
  end

  test "operator can access sensor stations index" do
    sign_in users(:operator)
    visit admin_sensor_stations_path

    assert_current_path admin_sensor_stations_path
  end

  test "operator can access river basins index" do
    sign_in users(:operator)
    visit admin_river_basins_path

    assert_current_path admin_river_basins_path
  end
end
