require "test_helper"

class AlertTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with all required fields" do
    alert = Alert.new(
      title: "Teste de alerta",
      description: "Descrição do alerta de teste.",
      severity: 2,
      alert_type: "manual"
    )
    assert alert.valid?
  end

  test "invalid without title" do
    alert = Alert.new(title: nil, description: "desc", severity: 1, alert_type: "manual")
    assert_not alert.valid?
    assert_includes alert.errors[:title], "can't be blank"
  end

  test "invalid without description" do
    alert = Alert.new(title: "Alerta", description: nil, severity: 1, alert_type: "manual")
    assert_not alert.valid?
    assert_includes alert.errors[:description], "can't be blank"
  end

  test "invalid without severity" do
    alert = Alert.new(title: "Alerta", description: "desc", severity: nil, alert_type: "manual")
    assert_not alert.valid?
    assert_includes alert.errors[:severity], "can't be blank"
  end

  test "invalid without alert_type" do
    alert = Alert.new(title: "Alerta", description: "desc", severity: 1, alert_type: nil)
    assert_not alert.valid?
    assert_includes alert.errors[:alert_type], "can't be blank"
  end

  test "severity must be between 1 and 4" do
    alert = Alert.new(title: "Alerta", description: "desc", alert_type: "manual")

    alert.severity = 0
    assert_not alert.valid?

    alert.severity = 5
    assert_not alert.valid?

    alert.severity = 1
    assert alert.valid?

    alert.severity = 4
    assert alert.valid?
  end

  test "alert_type must be automatic or manual" do
    alert = Alert.new(title: "Alerta", description: "desc", severity: 1, alert_type: "invalid")
    assert_not alert.valid?
    assert_includes alert.errors[:alert_type], "is not included in the list"
  end

  # ── Scopes ──

  test "active scope returns only active alerts" do
    active_alerts = Alert.active
    assert_includes active_alerts, alerts(:active_high)
    assert_includes active_alerts, alerts(:active_attention)
    assert_not_includes active_alerts, alerts(:resolved_alert)
  end

  test "unacknowledged scope returns active alerts without acknowledged_at" do
    unacknowledged = Alert.unacknowledged
    assert_includes unacknowledged, alerts(:active_high)
    assert_includes unacknowledged, alerts(:active_attention)
    assert_not_includes unacknowledged, alerts(:acknowledged_alert)
  end

  test "by_severity orders by severity descending" do
    ordered = Alert.by_severity
    assert ordered.first.severity >= ordered.last.severity
  end

  # ── Instance Methods ──

  test "acknowledged? returns true when acknowledged_at present" do
    assert alerts(:acknowledged_alert).acknowledged?
  end

  test "acknowledged? returns false when acknowledged_at nil" do
    assert_not alerts(:active_high).acknowledged?
  end

  test "resolved? returns true when status is resolved" do
    assert alerts(:resolved_alert).resolved?
  end

  test "resolved? returns false when status is active" do
    assert_not alerts(:active_high).resolved?
  end

  test "acknowledge! sets acknowledged_at and status" do
    alert = alerts(:active_high)
    alert.acknowledge!(users(:operator))

    assert_equal "acknowledged", alert.status
    assert_not_nil alert.acknowledged_at
  end

  test "resolve! sets resolved_at, resolved_by, and status" do
    alert = alerts(:active_high)
    user = users(:coordinator)
    alert.resolve!(user)

    assert_equal "resolved", alert.status
    assert_equal user, alert.resolved_by
    assert_not_nil alert.resolved_at
  end

  # ── Associations ──

  test "belongs to river basin optionally" do
    assert_equal river_basins(:bacia_belem), alerts(:active_high).river_basin
    assert_nil alerts(:active_attention).river_basin
  end

  test "belongs to neighborhood optionally" do
    assert_equal neighborhoods(:centro), alerts(:active_high).neighborhood
  end

  test "belongs to river optionally" do
    assert_equal rivers(:belem), alerts(:active_high).river
    assert_nil alerts(:active_attention).river
  end

  test "has many alert notifications" do
    assert_includes alerts(:active_high).alert_notifications, alert_notifications(:websocket_sent)
    assert_includes alerts(:active_high).alert_notifications, alert_notifications(:sms_pending)
  end
end
