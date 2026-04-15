require "test_helper"

class SendAlarmEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @alarm = alarms(:flood_alert_belem)
    @user  = users(:admin)
    ActionMailer::Base.deliveries.clear
  end

  test "enqueues on the notifications queue" do
    assert_enqueued_with(job: SendAlarmEmailJob, queue: "notifications") do
      SendAlarmEmailJob.perform_later(@alarm.id, @user.id, 3)
    end
  end

  test "perform_now delivers an email" do
    assert_emails 1 do
      SendAlarmEmailJob.perform_now(@alarm.id, @user.id, 3)
    end

    delivered = ActionMailer::Base.deliveries.last
    assert_equal [ @user.email_address ], delivered.to
    assert_match "Alerta Máximo", delivered.subject
  end

  test "is a no-op when the alarm is missing" do
    assert_emails 0 do
      SendAlarmEmailJob.perform_now(-1, @user.id, 3)
    end
  end

  test "is a no-op when the user is missing" do
    assert_emails 0 do
      SendAlarmEmailJob.perform_now(@alarm.id, -1, 3)
    end
  end

  test "is a no-op when the user is inactive" do
    inactive = users(:inactive)

    assert_emails 0 do
      SendAlarmEmailJob.perform_now(@alarm.id, inactive.id, 3)
    end
  end
end
