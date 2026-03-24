require "test_helper"

class WeatherIngestionCycleJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueues fetch job for sources that are due" do
    # Make open_meteo due
    data_sources(:open_meteo).update!(last_successful_fetch_at: 1.hour.ago)

    WeatherIngestionCycleJob.perform_now

    assert_enqueued_with(job: FetchOpenMeteoJob)
  end

  test "skips sources that were recently fetched" do
    data_sources(:open_meteo).update!(last_successful_fetch_at: 1.minute.ago)
    data_sources(:open_weather_map).update!(last_successful_fetch_at: 1.minute.ago)
    data_sources(:inmet).update!(last_successful_fetch_at: 1.minute.ago)
    data_sources(:cemaden).update!(last_successful_fetch_at: 1.minute.ago)
    data_sources(:simepar).update!(last_successful_fetch_at: 1.minute.ago)

    assert_no_enqueued_jobs(only: [FetchOpenMeteoJob, FetchOpenWeatherMapJob, FetchInmetJob, FetchCemadenJob]) do
      WeatherIngestionCycleJob.perform_now
    end
  end

  test "skips offline sources" do
    data_sources(:open_meteo).update!(
      status: "offline",
      consecutive_failures: 5,
      last_failed_fetch_at: 1.minute.ago,
      last_successful_fetch_at: 1.hour.ago
    )

    assert_no_enqueued_jobs(only: FetchOpenMeteoJob) do
      WeatherIngestionCycleJob.perform_now
    end
  end

  test "skips non-API sources (mqtt)" do
    data_sources(:iot_municipal).update!(last_successful_fetch_at: 1.hour.ago)

    assert_no_enqueued_jobs(only: FetchOpenMeteoJob) do
      # The mqtt source should be skipped entirely
    end
  end
end
