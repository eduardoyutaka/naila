require "test_helper"
require "webmock/minitest"

class OpenMeteoClientTest < ActiveSupport::TestCase
  setup do
    @data_source = data_sources(:open_meteo)
    @client = OpenMeteoClient.new(@data_source)
    @fixture = file_fixture("open_meteo_forecast_response.json").read
  end

  test "call returns forecast attribute hashes grouped in 3-hour buckets" do
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

  test "call groups hourly data into 3-hour buckets" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call

    # 9 hours = 3 buckets of 3 hours each
    assert_equal 3, result.size

    # First bucket: hours 0-2 → precipitation sum = 0.0 + 0.5 + 1.2 = 1.7
    assert_in_delta 1.7, result[0][:precipitation_mm], 0.01
    # Max probability in first bucket: 50
    assert_equal 50, result[0][:precipitation_probability]
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
