require "test_helper"

class WeatherObservationTest < ActiveSupport::TestCase
  test "current_conditions returns most recent observation" do
    result = WeatherObservation.current_conditions
    assert_not_nil result
    assert_equal weather_observations(:owm_recent), result
  end

  test "in_last scope returns observations within duration" do
    recent = WeatherObservation.in_last(1.hour)
    assert_includes recent, weather_observations(:owm_recent)
    assert_includes recent, weather_observations(:inmet_station)
  end

  test "in_last scope excludes old observations" do
    # Both fixtures are within 1h, but none should be outside
    old_obs = WeatherObservation.create!(
      source: "inmet",
      observed_at: 3.hours.ago,
      raw_data: {}
    )
    recent = WeatherObservation.in_last(1.hour)
    assert_not_includes recent, old_obs
  end
end
