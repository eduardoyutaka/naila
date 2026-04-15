require "test_helper"

class SmsDispatcherTest < ActiveSupport::TestCase
  setup do
    @previous_adapter = SmsDispatcher.adapter
    SmsDispatcher.adapter = SmsDispatcher::TestAdapter.new
  end

  teardown do
    SmsDispatcher.adapter = @previous_adapter
  end

  test "deliver forwards to the configured adapter" do
    SmsDispatcher.deliver(to: "+5541999000001", body: "Olá")

    calls = SmsDispatcher.adapter.calls
    assert_equal 1, calls.size
    assert_equal "+5541999000001", calls.first[:to]
    assert_equal "Olá", calls.first[:body]
  end

  test "deliver raises ArgumentError when to or body is blank" do
    assert_raises(ArgumentError) { SmsDispatcher.deliver(to: "", body: "x") }
    assert_raises(ArgumentError) { SmsDispatcher.deliver(to: "+5541", body: "") }
    assert_raises(ArgumentError) { SmsDispatcher.deliver(to: nil, body: "x") }
  end

  test "default_adapter_for returns LogAdapter outside production" do
    assert_instance_of SmsDispatcher::LogAdapter, SmsDispatcher.default_adapter_for("development")
    assert_instance_of SmsDispatcher::LogAdapter, SmsDispatcher.default_adapter_for("test")
  end

  test "default_adapter_for returns TwilioAdapter in production" do
    assert_instance_of SmsDispatcher::TwilioAdapter, SmsDispatcher.default_adapter_for("production")
  end

  test "TwilioAdapter classifies Twilio errors in the 20400-20499 range as permanent" do
    adapter = SmsDispatcher::TwilioAdapter.new
    rest_error = build_twilio_rest_error(20404)

    error = assert_raises(SmsDispatcher::PermanentError) do
      adapter.send(:classify_twilio_error, rest_error)
    end
    assert_match(/20404/, error.message)
  end

  test "TwilioAdapter classifies other Twilio errors as transient" do
    adapter = SmsDispatcher::TwilioAdapter.new
    rest_error = build_twilio_rest_error(20500)

    assert_raises(SmsDispatcher::TransientError) do
      adapter.send(:classify_twilio_error, rest_error)
    end
  end

  private

  def build_twilio_rest_error(code)
    response = Struct.new(:status_code, :body).new(500, { "code" => code })
    Twilio::REST::RestError.new("boom", response)
  end
end
