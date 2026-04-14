require "test_helper"
require "webmock/minitest"

class FetchCemadenJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @data_source = data_sources(:cemaden)
    @fixture = file_fixture("cemaden_pluviometer_response.json").read
  end

  test "creates sensor readings for each active CEMADEN station with a pluviometer" do
    stub_request(:get, %r{mapservices\.cemaden\.gov\.br/MapaInterativoWS/resources/horario/\d+/\d+})
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    # Two fixtures: cemaden_centro (6877) with pluv_cemaden_centro, estacao_belem (6877?) — let's rely on actual count
    expected = MonitoringStation.where(data_source: "CEMADEN", status: "active")
                                .joins(:sensors).where(sensors: { sensor_type: "pluviometer", status: "active" })
                                .distinct.count * 3

    assert_difference "SensorReading.count", expected do
      FetchCemadenJob.perform_now
    end
  end

  test "deduplicates readings on re-run" do
    stub_request(:get, %r{mapservices\.cemaden\.gov\.br/MapaInterativoWS/resources/horario/\d+/\d+})
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    FetchCemadenJob.perform_now

    assert_no_difference "SensorReading.count" do
      FetchCemadenJob.perform_now
    end
  end

  test "does not create records on API error" do
    stub_request(:get, %r{mapservices\.cemaden\.gov\.br/MapaInterativoWS/resources/horario/\d+/\d+})
      .to_return(status: 500, body: "Error")

    assert_no_difference "SensorReading.count" do
      FetchCemadenJob.perform_now
    end
  end

  test "skips stations without an active pluviometer" do
    # estacao_barigui is CEMADEN but has no sensors and is in maintenance —
    # the job must skip it without raising.
    stub_request(:get, %r{mapservices\.cemaden\.gov\.br/MapaInterativoWS/resources/horario/\d+/\d+})
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    assert_nothing_raised do
      FetchCemadenJob.perform_now
    end
  end
end
