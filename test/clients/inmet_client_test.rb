require "test_helper"
require "webmock/minitest"

class InmetClientTest < ActiveSupport::TestCase
  setup do
    @data_source = data_sources(:inmet)
    @client = InmetClient.new(@data_source)
    @fixture = file_fixture("inmet_station_response.json").read
  end

  test "call returns observation hashes for a station" do
    stub_request(:get, /apitempo\.inmet\.gov\.br\/estacao\/dados/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call(station_code: "A807")

    assert_kind_of Array, result
    assert_equal 2, result.size

    obs = result.first
    assert_equal "inmet", obs[:source]
    assert_equal "A807", obs[:station_code]
    assert_in_delta 22.5, obs[:temperature_c], 0.01
    assert_equal 78, obs[:humidity_pct]
    assert_in_delta 1.5, obs[:precipitation_mm], 0.01
  end

  test "call returns empty array on API error" do
    stub_request(:get, /apitempo\.inmet\.gov\.br\/estacao\/dados/)
      .to_return(status: 500, body: "Error")

    result = @client.call(station_code: "A807")

    assert_equal [], result
  end

  test "call returns empty array on connection error" do
    stub_request(:get, /apitempo\.inmet\.gov\.br\/estacao\/dados/)
      .to_timeout

    result = @client.call(station_code: "A807")

    assert_equal [], result
  end
end
