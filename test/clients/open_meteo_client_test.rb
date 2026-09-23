require "test_helper"
require "webmock/minitest"

class OpenMeteoClientTest < ActiveSupport::TestCase
  setup do
    @data_source = data_sources(:open_meteo)
    @client = OpenMeteoClient.new(@data_source)
    @fixture = file_fixture("open_meteo_forecast_response.json").read
  end

  test "call returns forecast attribute hashes for each hour" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call

    assert_kind_of Array, result
    assert result.any?

    forecast = result.first
    assert_equal "open_meteo", forecast[:source]
    assert forecast[:valid_from].present?
    assert forecast[:valid_until].present?
    assert_kind_of Numeric, forecast[:precipitation_mm]
    assert_kind_of Numeric, forecast[:precipitation_probability]
  end

  test "call returns one forecast per hour, matching OpenWeatherMap's granularity" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call

    # 9 hours in the fixture → 9 hourly forecasts, not 3-hour buckets
    assert_equal 9, result.size

    # Third hour: precipitation 1.2mm, probability 50%
    assert_in_delta 1.2, result[2][:precipitation_mm], 0.01
    assert_equal 50, result[2][:precipitation_probability]
    assert_equal result[2][:valid_from] + 1.hour, result[2][:valid_until]
  end

  test "call defaults a missing (nil) precipitation reading to 0.0 instead of raising" do
    fixture = JSON.parse(@fixture)
    fixture["hourly"]["precipitation"][2] = nil
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: fixture.to_json, headers: { "Content-Type" => "application/json" })

    result = @client.call

    assert_equal 0.0, result[2][:precipitation_mm]
  end

  test "call stores raw data in each forecast hash" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call
    forecast = result.first

    assert forecast[:raw_data].present?
    assert_kind_of Hash, forecast[:raw_data]
  end

  test "call returns empty array on API error" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 500, body: "Server Error")

    result = @client.call

    assert_equal [], result
  end

  test "call returns empty array on connection error" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_timeout

    result = @client.call

    assert_equal [], result
  end

  test "call includes soil moisture in raw_data" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call
    raw = result.first[:raw_data]

    assert raw.key?("soil_moisture_avg")
  end
end
