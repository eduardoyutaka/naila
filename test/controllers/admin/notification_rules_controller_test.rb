require "test_helper"

class Admin::NotificationRulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_notification_rules_path
    assert_response :success
  end

  test "index displays rule names" do
    get admin_notification_rules_path
    assert_select "td", text: /Email Administradores - Alerta/
    assert_select "td", text: /SMS Coordenadores - Emergência/
  end

  test "index filters by channel" do
    get admin_notification_rules_path(q: { channel: "sms" })
    assert_response :success
    assert_select "td", text: /SMS Coordenadores - Emergência/
    assert_select "td", text: /Email Administradores - Alerta/, count: 0
  end

  test "index filters by min_severity" do
    get admin_notification_rules_path(q: { min_severity: "4" })
    assert_response :success
    assert_select "td", text: /SMS Coordenadores - Emergência/
    assert_select "td", text: /Email Administradores - Alerta/, count: 0
  end

  test "index filters by enabled" do
    get admin_notification_rules_path(q: { enabled: "false" })
    assert_response :success
    assert_select "td", text: /Regra Desativada/
    assert_select "td", text: /Email Administradores - Alerta/, count: 0
  end

  # ── New / Create ──

  test "new renders successfully" do
    get new_admin_notification_rule_path
    assert_response :success
  end

  test "create with valid params creates rule and redirects" do
    assert_difference "NotificationRule.count", 1 do
      post admin_notification_rules_path, params: {
        notification_rule: {
          name: "Nova Regra Teste",
          channel: "email",
          min_severity: 2,
          target_admins: "1",
          target_coordinators: "0",
          target_operators: "0",
          enabled: "1"
        }
      }
    end
    assert_redirected_to admin_notification_rules_path
  end

  test "create with specific users assigns them" do
    assert_difference "NotificationRule.count", 1 do
      post admin_notification_rules_path, params: {
        notification_rule: {
          name: "Regra por usuário",
          channel: "email",
          min_severity: 2,
          user_ids: [ users(:operator).id.to_s ]
        }
      }
    end
    rule = NotificationRule.last
    assert_includes rule.users, users(:operator)
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "NotificationRule.count" do
      post admin_notification_rules_path, params: {
        notification_rule: { name: "", channel: "email", min_severity: 2 }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── Edit / Update ──

  test "edit renders successfully" do
    get edit_admin_notification_rule_path(notification_rules(:email_admins_alerta))
    assert_response :success
  end

  test "update with valid params updates rule and redirects" do
    patch admin_notification_rule_path(notification_rules(:email_admins_alerta)), params: {
      notification_rule: { name: "Novo Nome" }
    }
    assert_redirected_to admin_notification_rules_path
    assert_equal "Novo Nome", notification_rules(:email_admins_alerta).reload.name
  end

  test "update clears user_ids when form submits empty collection" do
    rule = notification_rules(:email_specific_user)
    assert_equal 1, rule.users.count

    patch admin_notification_rule_path(rule), params: {
      notification_rule: { target_admins: "1", user_ids: [ "" ] }
    }

    assert_redirected_to admin_notification_rules_path
    assert_empty rule.reload.users
  end

  # ── Destroy ──

  test "admin can destroy rule" do
    assert_difference "NotificationRule.count", -1 do
      delete admin_notification_rule_path(notification_rules(:disabled_rule))
    end
    assert_redirected_to admin_notification_rules_path
  end

  test "coordinator cannot destroy rule" do
    sign_in_as users(:coordinator)
    assert_no_difference "NotificationRule.count" do
      delete admin_notification_rule_path(notification_rules(:disabled_rule))
    end
    assert_redirected_to admin_root_path
  end

  test "operator cannot create rule" do
    sign_in_as users(:operator)
    assert_no_difference "NotificationRule.count" do
      post admin_notification_rules_path, params: {
        notification_rule: { name: "Não", channel: "email", min_severity: 2, target_admins: "1" }
      }
    end
    assert_redirected_to admin_root_path
  end

  test "coordinator can create rule" do
    sign_in_as users(:coordinator)
    assert_difference "NotificationRule.count", 1 do
      post admin_notification_rules_path, params: {
        notification_rule: {
          name: "Criada pelo coordenador",
          channel: "email",
          min_severity: 2,
          target_admins: "1"
        }
      }
    end
    assert_redirected_to admin_notification_rules_path
  end

  test "index requires authentication" do
    reset!
    get admin_notification_rules_path
    assert_redirected_to login_path
  end
end
