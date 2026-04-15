class SendAlarmEmailJob < ApplicationJob
  queue_as :notifications

  discard_on ActiveJob::DeserializationError
  retry_on Net::SMTPServerBusy, Net::OpenTimeout, Net::ReadTimeout,
           wait: :polynomially_longer, attempts: 5

  def perform(alarm_id, user_id, severity)
    alarm = Alarm.find_by(id: alarm_id)
    user  = User.find_by(id: user_id)
    return unless alarm && user&.active?

    AlarmMailer.notification(alarm, user, severity).deliver_now
  end
end
