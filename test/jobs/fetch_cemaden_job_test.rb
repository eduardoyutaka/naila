require "test_helper"
require "webmock/minitest"

class FetchCemadenJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @data_source = data_sources(:cemaden)
    @fixture = file_fixture("cemaden_pluviometer_response.json").read
  end

  test "creates sensor readings for CEMADEN stations" do
    stub_request(:get, /sjc\.salvar\.cemaden\.gov\.br\/resources\/dados/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    assert_difference "SensorReading.count", 3 do
      FetchCemadenJob.perform_now
    end
  end

  test "deduplicates readings on re-run" do
    stub_request(:get, /sjc\.salvar\.cemaden\.gov\.br\/resources\/dados/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    FetchCemadenJob.perform_now

    assert_no_difference "SensorReading.count" do
      FetchCemadenJob.perform_now
    end
  end

  test "does not create records on API error" do
    stub_request(:get, /sjc\.salvar\.cemaden\.gov\.br\/resources\/dados/)
      .to_return(status: 500, body: "Error")

    assert_no_difference "SensorReading.count" do
      FetchCemadenJob.perform_now
    end
  end
end
