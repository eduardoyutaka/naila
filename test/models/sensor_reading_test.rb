require "test_helper"

class SensorReadingTest < ActiveSupport::TestCase
  test "between returns readings within the inclusive range" do
    readings = SensorReading.where(sensor: sensors(:pluv_belem)).between(50.minutes.ago, 20.minutes.ago)
    assert_includes readings, sensor_readings(:pluv_centro_rain_2)     # 40 min ago
    assert_not_includes readings, sensor_readings(:pluv_centro_rain_1) # 10 min ago
    assert_not_includes readings, sensor_readings(:pluv_centro_rain_3) # 70 min ago
  end

  test "between excludes readings outside the range on both ends" do
    readings = SensorReading.where(sensor: sensors(:pluv_belem)).between(2.days.ago, 1.day.ago)
    assert_empty readings
  end
end
