require "test_helper"
require "webmock/minitest"

class OpenWeatherMapClientTest < ActiveSupport::TestCase
  setup do
    @data_source = data_sources(:open_weather_map)
    @client = OpenWeatherMapClient.new(@data_source)
    @fixture = file_fixture("open_weather_map_onecall_response.json").read
  end

  test "call returns observations and forecasts" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call

    assert_kind_of Hash, result
    assert result[:observations].any?
    assert result[:forecasts].any?
  end

  test "call parses current weather into observation" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call
    obs = result[:observations].first

    assert_equal "open_weather_map", obs[:source]
    assert_in_delta 22.5, obs[:temperature_c], 0.01
    assert_equal 78, obs[:humidity_pct]
    assert_in_delta 1.5, obs[:precipitation_mm], 0.01
    assert_equal "chuva leve", obs[:weather_condition]
  end

  test "call parses hourly data into forecasts" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call
    forecasts = result[:forecasts]

    assert_equal 3, forecasts.size
    forecast = forecasts.first
    assert_equal "open_weather_map", forecast[:source]
    assert_in_delta 1.5, forecast[:precipitation_mm], 0.01
    assert_in_delta 70.0, forecast[:precipitation_probability], 0.01
  end

  test "call returns empty result on API error" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_return(status: 401, body: '{"message":"Invalid API key"}')

    result = @client.call

    assert_equal({ observations: [], forecasts: [] }, result)
  end

  test "call returns empty result on connection error" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_timeout

    result = @client.call

    assert_equal({ observations: [], forecasts: [] }, result)
  end
end
