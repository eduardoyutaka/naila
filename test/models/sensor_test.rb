require "test_helper"

class SensorTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with all required attributes" do
    sensor = Sensor.new(
      monitoring_station: monitoring_stations(:estacao_belem),
      sensor_type: "pluviometer",
      external_id: "TEST-PLUV-001"
    )
    assert sensor.valid?
  end

  test "invalid without external_id" do
    sensor = Sensor.new(monitoring_station: monitoring_stations(:estacao_belem), sensor_type: "pluviometer")
    assert_not sensor.valid?
    assert_includes sensor.errors[:external_id], "não pode ficar em branco"
  end

  test "invalid without sensor_type" do
    sensor = Sensor.new(monitoring_station: monitoring_stations(:estacao_belem), external_id: "TEST-001")
    assert_not sensor.valid?
    assert_includes sensor.errors[:sensor_type], "não pode ficar em branco"
  end

  test "invalid without monitoring_station" do
    sensor = Sensor.new(sensor_type: "pluviometer", external_id: "TEST-001")
    assert_not sensor.valid?
  end

  test "external_id must be unique" do
    existing = sensors(:pluv_belem)
    duplicate = Sensor.new(
      monitoring_station: monitoring_stations(:estacao_belem),
      sensor_type: "pluviometer",
      external_id: existing.external_id
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:external_id], "já foi utilizado"
  end

  # ── Associations ──

  test "belongs to monitoring_station" do
    assert_equal monitoring_stations(:estacao_belem), sensors(:pluv_belem).monitoring_station
  end

  test "has many sensor_readings" do
    assert_respond_to sensors(:pluv_belem), :sensor_readings
  end

  # ── Enums ──

  test "sensor_type enum values" do
    assert sensors(:pluv_belem).sensor_type_pluviometer?
  end

  test "status enum values" do
    assert sensors(:pluv_belem).status_active?
    assert sensors(:pluv_barigui).status_maintenance?
  end

  # ── Scopes ──

  test "online scope returns active sensors" do
    active_ids = Sensor.online.pluck(:id)
    assert_includes active_ids, sensors(:pluv_belem).id
    assert_not_includes active_ids, sensors(:pluv_barigui).id
  end

  test "by_type scope filters by sensor_type" do
    pluviometers = Sensor.by_type("pluviometer")
    assert_includes pluviometers, sensors(:pluv_belem)
    assert_empty Sensor.by_type("weather_station")
  end
end
