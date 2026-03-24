require "test_helper"
require "webmock/minitest"

class BaseClientTest < ActiveSupport::TestCase
  setup do
    @data_source = data_sources(:open_meteo)
    @client = BaseClient.new(@data_source)
  end

  test "fetch calls the block and records success" do
    stub_request(:get, "https://api.open-meteo.com/test")
      .to_return(status: 200, body: '{"ok": true}', headers: { "Content-Type" => "application/json" })

    result = @client.fetch { |conn| conn.get("/test") }

    assert result
    @data_source.reload
    assert_equal "active", @data_source.status
    assert_equal 0, @data_source.consecutive_failures
  end

  test "fetch records failure on HTTP error" do
    stub_request(:get, "https://api.open-meteo.com/test")
      .to_return(status: 500, body: "Internal Server Error")

    result = @client.fetch { |conn| conn.get("/test") }

    assert_nil result
    @data_source.reload
    assert_equal "degraded", @data_source.status
    assert_equal 1, @data_source.consecutive_failures
  end

  test "fetch records failure on connection error" do
    stub_request(:get, "https://api.open-meteo.com/test")
      .to_timeout

    result = @client.fetch { |conn| conn.get("/test") }

    assert_nil result
    @data_source.reload
    assert_equal "degraded", @data_source.status
  end

  test "fetch skips request when data source is offline" do
    @data_source.update!(status: "offline", consecutive_failures: 5, last_failed_fetch_at: 1.minute.ago)

    result = @client.fetch { |conn| conn.get("/test") }

    assert_nil result
    # No HTTP request should have been made
  end

  test "fetch allows retry probe when offline and cooldown passed" do
    @data_source.update!(status: "offline", consecutive_failures: 5, last_failed_fetch_at: 10.minutes.ago)

    stub_request(:get, "https://api.open-meteo.com/test")
      .to_return(status: 200, body: '{"ok": true}', headers: { "Content-Type" => "application/json" })

    result = @client.fetch { |conn| conn.get("/test") }

    assert result
    @data_source.reload
    assert_equal "active", @data_source.status
  end

  test "connection uses correct base url" do
    conn = @client.connection
    assert_equal "https://api.open-meteo.com", conn.url_prefix.to_s.chomp("/")
  end

  test "connection has retry middleware" do
    conn = @client.connection
    handler_names = conn.builder.handlers.map(&:name)
    assert_includes handler_names, "Faraday::Retry::Middleware"
  end
end
