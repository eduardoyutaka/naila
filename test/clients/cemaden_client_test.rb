require "test_helper"
require "webmock/minitest"

class CemadenClientTest < ActiveSupport::TestCase
  setup do
    @data_source = data_sources(:cemaden)
    @client = CemadenClient.new(@data_source)
    @fixture = file_fixture("cemaden_pluviometer_response.json").read
  end

  test "call returns sensor reading hashes" do
    stub_request(:get, %r{mapservices\.cemaden\.gov\.br/MapaInterativoWS/resources/horario/6877/\d+})
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call(station_code: "6877")

    assert_kind_of Array, result
    assert_equal 3, result.size

    reading = result.first
    assert_equal "cemaden", reading[:source]
    assert_equal "6877", reading[:station_code]
    assert_in_delta 2.4, reading[:value], 0.01
    assert_equal "mm", reading[:unit]
    assert_equal "precipitation", reading[:reading_type]
    assert_equal Time.zone.local(2026, 3, 23, 10, 0, 0), reading[:recorded_at]
  end

  test "call skips null values in the acumulados matrix" do
    fixture = <<~JSON
      {
        "horarios": ["9h", "10h", "11h"],
        "datas": ["23/03/2026"],
        "acumulados": [[null, 1.2, null]]
      }
    JSON
    stub_request(:get, %r{mapservices\.cemaden\.gov\.br/MapaInterativoWS/resources/horario/6877/\d+})
      .to_return(status: 200, body: fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call(station_code: "6877")

    assert_equal 1, result.size
    assert_in_delta 1.2, result.first[:value], 0.01
  end

  test "call returns empty array on API error" do
    stub_request(:get, %r{mapservices\.cemaden\.gov\.br/MapaInterativoWS/resources/horario/6877/\d+})
      .to_return(status: 500, body: "Error")

    result = @client.call(station_code: "6877")

    assert_equal [], result
  end

  test "call returns empty array on connection error" do
    stub_request(:get, %r{mapservices\.cemaden\.gov\.br/MapaInterativoWS/resources/horario/6877/\d+})
      .to_timeout

    result = @client.call(station_code: "6877")

    assert_equal [], result
  end
end
