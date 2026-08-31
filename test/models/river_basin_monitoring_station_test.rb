require "test_helper"

class RiverBasinMonitoringStationTest < ActiveSupport::TestCase
  test "valid with a river_basin and monitoring_station" do
    join = RiverBasinMonitoringStation.new(
      river_basin: river_basins(:bacia_barigui),
      monitoring_station: monitoring_stations(:estacao_belem)
    )
    assert join.valid?
  end

  test "invalid without river_basin" do
    join = RiverBasinMonitoringStation.new(monitoring_station: monitoring_stations(:estacao_belem))
    assert_not join.valid?
  end

  test "invalid without monitoring_station" do
    join = RiverBasinMonitoringStation.new(river_basin: river_basins(:bacia_barigui))
    assert_not join.valid?
  end

  test "monitoring_station_id must be unique within a river_basin" do
    existing = river_basin_monitoring_stations(:belem_estacao_belem)
    duplicate = RiverBasinMonitoringStation.new(
      river_basin: existing.river_basin,
      monitoring_station: existing.monitoring_station
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:monitoring_station_id], "já foi utilizado"
  end

  test "the same station can be configured for more than one basin" do
    shared_station = monitoring_stations(:estacao_belem)
    join = RiverBasinMonitoringStation.new(
      river_basin: river_basins(:bacia_barigui),
      monitoring_station: shared_station
    )
    assert join.valid?
  end
end
