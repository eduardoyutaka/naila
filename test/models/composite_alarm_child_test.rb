require "test_helper"

class CompositeAlarmChildTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with composite parent and metric child" do
    link = CompositeAlarmChild.new(
      composite_alarm: alarms(:composite_flood_belem),
      child_alarm: alarms(:disabled_alarm)
    )
    assert link.valid?
  end

  test "invalid without composite_alarm" do
    link = composite_alarm_children(:flood_precip)
    link.composite_alarm = nil
    assert_not link.valid?
  end

  test "invalid without child_alarm" do
    link = composite_alarm_children(:flood_precip)
    link.child_alarm = nil
    assert_not link.valid?
  end

  test "invalid when composite_alarm is not composite type" do
    link = CompositeAlarmChild.new(
      composite_alarm: alarms(:precip_3h_belem),
      child_alarm: alarms(:river_level_belem)
    )
    assert_not link.valid?
    assert_includes link.errors[:composite_alarm], "must be a composite alarm"
  end

  test "invalid when child_alarm is composite type" do
    link = CompositeAlarmChild.new(
      composite_alarm: alarms(:composite_flood_belem),
      child_alarm: alarms(:composite_flood_belem)
    )
    assert_not link.valid?
    assert_includes link.errors[:child_alarm], "cannot be a composite alarm"
  end

  test "invalid with duplicate composite_alarm and child_alarm pair" do
    existing = composite_alarm_children(:flood_precip)
    duplicate = CompositeAlarmChild.new(
      composite_alarm: existing.composite_alarm,
      child_alarm: existing.child_alarm
    )
    assert_not duplicate.valid?
  end

  # ── Associations ──

  test "belongs to composite_alarm" do
    assert_equal alarms(:composite_flood_belem), composite_alarm_children(:flood_precip).composite_alarm
  end

  test "belongs to child_alarm" do
    assert_equal alarms(:precip_3h_belem), composite_alarm_children(:flood_precip).child_alarm
  end
end
