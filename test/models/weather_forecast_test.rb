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

  # ── map_timeline ──

  test "map_timeline returns array of hashes with expected keys" do
    timeline = WeatherForecast.map_timeline(hours: 6)
    assert_kind_of Array, timeline
    assert timeline.size > 0

    entry = timeline.first
    %i[valid_from valid_until precipitation_mm precipitation_probability
       temperature_max_c temperature_min_c weather_code].each do |key|
      assert entry.key?(key), "Expected key #{key} in timeline entry"
    end
  end

  test "map_timeline excludes expired forecasts" do
    timeline = WeatherForecast.map_timeline(hours: 6)
    valid_froms = timeline.map { |e| e[:valid_from] }
    expired = weather_forecasts(:open_meteo_expired)
    assert_not_includes valid_froms, expired.valid_from.iso8601
  end

  test "map_timeline returns entries ordered by valid_from" do
    timeline = WeatherForecast.map_timeline(hours: 72)
    valid_froms = timeline.map { |e| Time.parse(e[:valid_from]) }
    assert_equal valid_froms, valid_froms.sort
  end

  test "map_timeline defaults weather_code to 0 when raw_data has no weather_codes" do
    timeline = WeatherForecast.map_timeline(hours: 6)
    timeline.each do |entry|
      assert_equal 0, entry[:weather_code]
    end
  end

  test "map_timeline picks most severe weather code from raw_data" do
    forecast = weather_forecasts(:open_meteo_current)
    forecast.update_columns(raw_data: { "weather_codes" => [2, 63, 3] }.to_json)

    timeline = WeatherForecast.map_timeline(hours: 6)
    entry = timeline.find { |e| e[:valid_from] == forecast.valid_from.iso8601 }
    assert_equal 63, entry[:weather_code]
  end

  test "map_timeline respects hours parameter" do
    short = WeatherForecast.map_timeline(hours: 1)
    long = WeatherForecast.map_timeline(hours: 72)
    assert long.size >= short.size
  end

  test "map_timeline returns empty array when no forecasts" do
    WeatherForecast.destroy_all
    assert_equal [], WeatherForecast.map_timeline(hours: 6)
  end

  test "map_timeline rounds precipitation values" do
    timeline = WeatherForecast.map_timeline(hours: 6)
    timeline.each do |entry|
      assert_equal entry[:precipitation_mm], entry[:precipitation_mm].round(1)
    end
  end

  # ── wmo_severity ──

  test "wmo_severity returns 0 for clear sky (code 0)" do
    assert_equal 0, WeatherForecast.send(:wmo_severity, 0)
  end

  test "wmo_severity returns 1 for fog (code 45)" do
    assert_equal 1, WeatherForecast.send(:wmo_severity, 45)
  end

  test "wmo_severity returns 2 for drizzle (code 51)" do
    assert_equal 2, WeatherForecast.send(:wmo_severity, 51)
  end

  test "wmo_severity returns 3 for rain lower boundary (code 61)" do
    assert_equal 3, WeatherForecast.send(:wmo_severity, 61)
  end

  test "wmo_severity returns 4 for rain shower lower boundary (code 80)" do
    assert_equal 4, WeatherForecast.send(:wmo_severity, 80)
  end

  test "wmo_severity returns 5 for thunderstorm lower boundary (code 95)" do
    assert_equal 5, WeatherForecast.send(:wmo_severity, 95)
  end

  test "wmo_severity returns 5 for thunderstorm upper boundary (code 99)" do
    assert_equal 5, WeatherForecast.send(:wmo_severity, 99)
  end
end
