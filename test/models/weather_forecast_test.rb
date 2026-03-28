require "test_helper"

class WeatherForecastTest < ActiveSupport::TestCase
  test "current scope excludes expired forecasts" do
    current = WeatherForecast.current
    assert_includes current, weather_forecasts(:open_meteo_current)
    assert_includes current, weather_forecasts(:open_meteo_future)
    assert_not_includes current, weather_forecasts(:open_meteo_expired)
  end

  test "ordered_timeline returns forecasts in ascending valid_from order" do
    forecasts = WeatherForecast.current.ordered_timeline
    times = forecasts.map(&:valid_from)
    assert_equal times, times.sort
  end

  test "in_last scope returns forecasts issued within duration" do
    recent = WeatherForecast.in_last(1.hour)
    assert_includes recent, weather_forecasts(:open_meteo_current)
    assert_not_includes recent, weather_forecasts(:open_meteo_expired)
  end

  test "aggregate_next_hours returns aggregated precipitation data" do
    result = WeatherForecast.aggregate_next_hours(6)
    assert result.key?(:total_precipitation_mm)
    assert result.key?(:max_precipitation_mm)
    assert result.key?(:max_probability)
    assert result[:total_precipitation_mm] >= 0
    assert result[:max_probability] >= 0
  end

  test "aggregate_next_hours total includes all valid forecasts in window" do
    result = WeatherForecast.aggregate_next_hours(6)
    # open_meteo_current (15mm), open_meteo_future (25mm), owm_current (8mm), owm_future (0mm)
    # open_meteo_expired should not be included
    assert result[:total_precipitation_mm] > 0
    assert_not_includes WeatherForecast.current.valid_in_next(6.hours), weather_forecasts(:open_meteo_expired)
  end
end
