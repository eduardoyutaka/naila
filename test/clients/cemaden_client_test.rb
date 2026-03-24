require "test_helper"
require "webmock/minitest"

class CemadenClientTest < ActiveSupport::TestCase
  setup do
    @data_source = data_sources(:cemaden)
    @client = CemadenClient.new(@data_source)
    @fixture = file_fixture("cemaden_pluviometer_response.json").read
  end

  test "call returns sensor reading hashes" do
    stub_request(:get, /sjc\.salvar\.cemaden\.gov\.br\/resources\/dados/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    result = @client.call

    assert_kind_of Array, result
    assert_equal 3, result.size

    reading = result.first
    assert_equal "cemaden", reading[:source]
    assert_equal "410690701A", reading[:station_code]
    assert_in_delta 2.4, reading[:value], 0.01
    assert_equal "mm", reading[:unit]
    assert_equal "precipitation", reading[:reading_type]
  end

  test "call returns empty array on API error" do
    stub_request(:get, /sjc\.salvar\.cemaden\.gov\.br\/resources\/dados/)
      .to_return(status: 500, body: "Error")

    result = @client.call

    assert_equal [], result
  end

  test "call returns empty array on connection error" do
    stub_request(:get, /sjc\.salvar\.cemaden\.gov\.br\/resources\/dados/)
      .to_timeout

    result = @client.call

    assert_equal [], result
  end
end
