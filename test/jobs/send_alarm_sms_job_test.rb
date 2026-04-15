require "test_helper"

class SendAlarmSmsJobTest < ActiveJob::TestCase
  setup do
    @alarm = alarms(:flood_alert_belem)
    @user  = users(:admin) # has phone_number
    @previous_adapter = SmsDispatcher.adapter
    SmsDispatcher.adapter = SmsDispatcher::TestAdapter.new
  end

  teardown do
    SmsDispatcher.adapter = @previous_adapter
  end

  test "enqueues on the notifications queue" do
    assert_enqueued_with(job: SendAlarmSmsJob, queue: "notifications") do
      SendAlarmSmsJob.perform_later(@alarm.id, @user.id, 3)
    end
  end

  test "perform_now dispatches an SMS to the user's phone number" do
    SendAlarmSmsJob.perform_now(@alarm.id, @user.id, 3)

    calls = SmsDispatcher.adapter.calls
    assert_equal 1, calls.size
    assert_equal @user.phone_number, calls.first[:to]
    assert_match "Alerta Máximo", calls.first[:body]
  end

  test "is a no-op when the alarm is missing" do
    SendAlarmSmsJob.perform_now(-1, @user.id, 3)
    assert_empty SmsDispatcher.adapter.calls
  end

  test "is a no-op when the user is missing" do
    SendAlarmSmsJob.perform_now(@alarm.id, -1, 3)
    assert_empty SmsDispatcher.adapter.calls
  end

  test "is a no-op when the user is inactive" do
    inactive = users(:inactive)
    SendAlarmSmsJob.perform_now(@alarm.id, inactive.id, 3)
    assert_empty SmsDispatcher.adapter.calls
  end

  test "is a no-op when the user has no phone number" do
    operator = users(:operator) # has no phone_number per fixtures
    SendAlarmSmsJob.perform_now(@alarm.id, operator.id, 3)
    assert_empty SmsDispatcher.adapter.calls
  end
end
