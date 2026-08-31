require "test_helper"

class AlarmMonitoringStationTest < ActiveSupport::TestCase
  test "valid with an alarm and monitoring_station" do
    join = AlarmMonitoringStation.new(
      alarm: alarms(:precip_3h_belem),
      monitoring_station: monitoring_stations(:estacao_belem)
    )
    assert join.valid?
  end

  test "invalid without alarm" do
    join = AlarmMonitoringStation.new(monitoring_station: monitoring_stations(:estacao_belem))
    assert_not join.valid?
  end

  test "invalid without monitoring_station" do
    join = AlarmMonitoringStation.new(alarm: alarms(:precip_3h_belem))
    assert_not join.valid?
  end

  test "monitoring_station_id must be unique within an alarm" do
    existing = AlarmMonitoringStation.create!(
      alarm: alarms(:precip_3h_belem), monitoring_station: monitoring_stations(:estacao_belem)
    )
    duplicate = AlarmMonitoringStation.new(alarm: existing.alarm, monitoring_station: existing.monitoring_station)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:monitoring_station_id], "já foi utilizado"
  end

  test "the same station can be scoped to more than one alarm" do
    station = monitoring_stations(:estacao_belem)
    AlarmMonitoringStation.create!(alarm: alarms(:precip_3h_belem), monitoring_station: station)

    join = AlarmMonitoringStation.new(alarm: alarms(:flood_alert_belem), monitoring_station: station)
    assert join.valid?
  end
end
