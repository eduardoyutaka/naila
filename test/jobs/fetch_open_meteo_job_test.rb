require "test_helper"
require "webmock/minitest"

class FetchOpenMeteoJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @data_source = data_sources(:open_meteo)
    @fixture = file_fixture("open_meteo_forecast_response.json").read
  end

  test "creates weather forecast records" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    assert_difference "WeatherForecast.count", 3 do
      FetchOpenMeteoJob.perform_now
    end

    forecast = WeatherForecast.last
    assert_equal "open_meteo", forecast.source
  end

  test "deduplicates on re-run" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    FetchOpenMeteoJob.perform_now

    assert_no_difference "WeatherForecast.count" do
      FetchOpenMeteoJob.perform_now
    end
  end

  test "enqueues AlarmEvaluationJob after successful fetch" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 200, body: @fixture, headers: { "Content-Type" => "application/json" })

    assert_enqueued_with(job: AlarmEvaluationJob) do
      FetchOpenMeteoJob.perform_now
    end
  end

  test "does not enqueue AlarmEvaluationJob on failure" do
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 500, body: "Error")

    assert_no_enqueued_jobs(only: AlarmEvaluationJob) do
      FetchOpenMeteoJob.perform_now
    end
  end
end
