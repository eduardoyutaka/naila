require "test_helper"
require "webmock/minitest"

class FetchOpenWeatherMapJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @data_source = data_sources(:open_weather_map)
    @fixture = file_fixture("open_weather_map_onecall_response.json").read
  end

  test "creates weather observation and forecast records" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    assert_difference "WeatherObservation.count", 1 do
      assert_difference "WeatherForecast.count", 3 do
        FetchOpenWeatherMapJob.perform_now
      end
    end
  end

  test "deduplicates observations on re-run" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    FetchOpenWeatherMapJob.perform_now

    assert_no_difference "WeatherObservation.count" do
      FetchOpenWeatherMapJob.perform_now
    end
  end

  test "enqueues RiskAssessmentJob after successful fetch" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    assert_enqueued_with(job: RiskAssessmentJob) do
      FetchOpenWeatherMapJob.perform_now
    end
  end

  test "does not create records on API error" do
    stub_request(:get, /api\.openweathermap\.org\/data\/3\.0\/onecall/)
      .to_return(status: 401, body: '{"message":"Invalid API key"}')

    assert_no_difference "WeatherObservation.count" do
      FetchOpenWeatherMapJob.perform_now
    end
  end
end
