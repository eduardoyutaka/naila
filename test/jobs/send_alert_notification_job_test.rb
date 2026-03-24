require "test_helper"

class SendAlertNotificationJobTest < ActiveSupport::TestCase
  setup do
    @alert = alerts(:active_high)
    @notification = AlertNotification.create!(
      alert: @alert,
      channel: "websocket",
      status: "pending"
    )
  end

  test "marks notification as sent on success" do
    SendAlertNotificationJob.perform_now(@notification.id)

    @notification.reload
    assert_equal "sent", @notification.status
    assert @notification.sent_at.present?
  end

  test "marks notification as failed on error" do
    notification = AlertNotification.create!(
      alert: @alert,
      channel: "websocket",
      status: "pending"
    )

    job = SendAlertNotificationJob.new
    original_method = job.method(:deliver_websocket)

    job.define_singleton_method(:deliver_websocket) { |_n| raise StandardError, "broadcast failed" }
    job.perform(notification.id)

    notification.reload
    assert_equal "failed", notification.status
    assert_equal "broadcast failed", notification.failure_reason
  end

  test "skips already sent notifications" do
    @notification.update!(status: "sent", sent_at: 1.minute.ago)

    SendAlertNotificationJob.perform_now(@notification.id)

    @notification.reload
    assert @notification.sent_at < 30.seconds.ago
  end
end
