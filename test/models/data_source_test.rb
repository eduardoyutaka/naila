require "test_helper"

class DataSourceTest < ActiveSupport::TestCase
  test "due_for_fetch? returns true when never fetched" do
    source = data_sources(:open_meteo)
    source.update!(last_successful_fetch_at: nil)

    assert source.due_for_fetch?
  end

  test "due_for_fetch? returns true when interval has elapsed" do
    source = data_sources(:open_meteo)
    source.update!(last_successful_fetch_at: 1.hour.ago)

    assert source.due_for_fetch?
  end

  test "due_for_fetch? returns false when recently fetched" do
    source = data_sources(:open_meteo)
    source.update!(last_successful_fetch_at: 1.minute.ago)

    assert_not source.due_for_fetch?
  end

  test "can_retry? returns false when active" do
    source = data_sources(:open_meteo)

    assert_not source.can_retry?
  end

  test "can_retry? returns true when offline and cooldown passed" do
    source = data_sources(:offline_source)
    source.update!(last_failed_fetch_at: 10.minutes.ago)

    assert source.can_retry?
  end

  test "can_retry? returns false when offline but recently failed" do
    source = data_sources(:offline_source)
    source.update!(last_failed_fetch_at: 1.minute.ago)

    assert_not source.can_retry?
  end

  test "client_class returns correct class for each source" do
    assert_equal OpenMeteoClient, data_sources(:open_meteo).client_class
    assert_equal OpenWeatherMapClient, data_sources(:open_weather_map).client_class
    assert_equal InmetClient, data_sources(:inmet).client_class
    assert_equal CemadenClient, data_sources(:cemaden).client_class
    assert_equal SimeparClient, data_sources(:simepar).client_class
  end

  test "client_class returns nil for unknown source" do
    source = data_sources(:iot_municipal)

    assert_nil source.client_class
  end

  test "record_success! resets failures and updates timestamp" do
    source = data_sources(:offline_source)
    source.record_success!

    assert_equal "active", source.status
    assert_equal 0, source.consecutive_failures
    assert_in_delta Time.current, source.last_successful_fetch_at, 2
  end

  test "record_failure! increments failures and sets degraded" do
    source = data_sources(:open_meteo)
    source.record_failure!

    assert_equal "degraded", source.status
    assert_equal 1, source.consecutive_failures
  end

  test "record_failure! sets offline after 3 failures" do
    source = data_sources(:open_meteo)
    source.update!(consecutive_failures: 2)
    source.record_failure!

    assert_equal "offline", source.status
    assert_equal 3, source.consecutive_failures
  end
end
