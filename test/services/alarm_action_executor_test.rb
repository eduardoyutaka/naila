require "test_helper"

class AlarmActionExecutorTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  setup do
    @alarm = alarms(:disabled_alarm)
    @alarm.update!(enabled: true)
    @alarm.alarm_actions.create!(
      trigger_state: "alarm",
      action_type: "notification",
      configuration: {},
      enabled: true
    )
  end

  # ── Notification actions ──

  test "broadcasts to alarms ActionCable channel on notification action" do
    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "broadcast payload contains alarm state info" do
    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end

    payload = ActiveSupport::JSON.decode(broadcasts("alarms").last)
    assert_equal "alarm_state_change", payload["event_type"]
    assert_equal @alarm.id, payload["alarm_id"]
    assert_equal "alarm", payload["state"]
    assert_nil payload["current_severity"]  # disabled_alarm has no current_severity
  end

  test "skips disabled actions" do
    @alarm.alarm_actions.update_all(enabled: false)

    assert_no_broadcasts("alarms") do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "executes ok state actions" do
    @alarm.alarm_actions.create!(
      trigger_state: "ok",
      action_type: "notification",
      configuration: {},
      enabled: true
    )

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "ok")
    end
  end

  test "executes insufficient_data state actions" do
    @alarm.alarm_actions.create!(
      trigger_state: "insufficient_data",
      action_type: "notification",
      configuration: {},
      enabled: true
    )

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "insufficient_data")
    end
  end

  # ── Rule-based email/SMS dispatch ──

  test "does not enqueue any email/sms jobs when transitioning to ok" do
    @alarm.update!(current_severity: 3)

    assert_no_enqueued_jobs only: [ SendAlarmEmailJob, SendAlarmSmsJob ] do
      AlarmActionExecutor.execute(@alarm, "ok")
    end
  end

  test "does not enqueue any email/sms jobs when transitioning to insufficient_data" do
    @alarm.update!(current_severity: 3)

    assert_no_enqueued_jobs only: [ SendAlarmEmailJob, SendAlarmSmsJob ] do
      AlarmActionExecutor.execute(@alarm, "insufficient_data")
    end
  end

  test "does not enqueue jobs when current_severity is nil" do
    # @alarm has no current_severity
    assert_no_enqueued_jobs only: [ SendAlarmEmailJob, SendAlarmSmsJob ] do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "enqueues email job per recipient from enabled email rules on transition to alarm" do
    @alarm.update!(current_severity: 3)
    # email_admins_alerta fires at sev 2+ and targets admins
    # sms_all_roles_high fires at sev 3+ and targets everyone — not email

    assert_enqueued_with(job: SendAlarmEmailJob, args: [ @alarm.id, users(:admin).id, 3 ]) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "enqueues sms jobs only for users with phone numbers" do
    @alarm.update!(current_severity: 3)
    # sms_all_roles_high fires at sev 3+ and targets all roles. admin/coordinator/inactive
    # have phone numbers; operator has none; inactive is filtered out.

    AlarmActionExecutor.execute(@alarm, "alarm")

    sms_jobs = enqueued_jobs.select { |j| j[:job] == SendAlarmSmsJob }
    user_ids = sms_jobs.map { |j| j[:args][1] }
    assert_includes user_ids, users(:admin).id
    assert_includes user_ids, users(:coordinator).id
    assert_not_includes user_ids, users(:operator).id
    assert_not_includes user_ids, users(:inactive).id
  end

  test "dedupes users matched by multiple rules" do
    @alarm.update!(current_severity: 4)
    # At sev 4, both email_admins_alerta (email, sev 2+) matches admin twice if we had
    # duplicate rules. We have one rule matching admin for email, and one matching
    # the operator explicitly (email_specific_user). Each user should appear once per channel.

    AlarmActionExecutor.execute(@alarm, "alarm")

    email_jobs = enqueued_jobs.select { |j| j[:job] == SendAlarmEmailJob }
    admin_jobs = email_jobs.select { |j| j[:args][1] == users(:admin).id }
    assert_equal 1, admin_jobs.size, "admin should receive exactly one email job"
  end

  test "skips disabled rules" do
    @alarm.update!(current_severity: 1)
    # disabled_rule targets admins at sev 1 via email but is disabled.
    # email_admins_alerta requires sev >= 2 and does not fire at sev 1.

    assert_no_enqueued_jobs only: [ SendAlarmEmailJob, SendAlarmSmsJob ] do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "still broadcasts websocket for every state transition" do
    @alarm.update!(current_severity: 3)

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  # ── min_severity filtering ──

  test "skips action when current_severity is below min_severity" do
    @alarm.update!(current_severity: 1)
    @alarm.alarm_actions.update_all(min_severity: 2)

    assert_no_broadcasts("alarms") do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "executes action when current_severity meets min_severity" do
    @alarm.update!(current_severity: 2)
    @alarm.alarm_actions.update_all(min_severity: 2)

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

  test "executes action with no min_severity regardless of current_severity" do
    @alarm.update!(current_severity: 1)
    # min_severity is nil by default

    assert_broadcasts("alarms", 1) do
      AlarmActionExecutor.execute(@alarm, "alarm")
    end
  end

end
