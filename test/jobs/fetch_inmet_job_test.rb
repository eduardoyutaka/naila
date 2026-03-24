require "test_helper"
require "webmock/minitest"

class FetchInmetJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @data_source = data_sources(:inmet)
    @fixture = file_fixture("inmet_station_response.json").read
  end

  test "creates weather observations for INMET stations" do
    stub_request(:get, /apitempo\.inmet\.gov\.br\/estacao\/dados/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    assert_difference "WeatherObservation.count", 2 do
      FetchInmetJob.perform_now
    end

    obs = WeatherObservation.where(source: "inmet").last
    assert_equal "A807", obs.station_code
  end

  test "deduplicates observations on re-run" do
    stub_request(:get, /apitempo\.inmet\.gov\.br\/estacao\/dados/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    FetchInmetJob.perform_now

    assert_no_difference "WeatherObservation.count" do
      FetchInmetJob.perform_now
    end
  end

  test "does not create records on API error" do
    stub_request(:get, /apitempo\.inmet\.gov\.br\/estacao\/dados/)
      .to_return(status: 500, body: "Error")

    assert_no_difference "WeatherObservation.count" do
      FetchInmetJob.perform_now
    end
  end
end
