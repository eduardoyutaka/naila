class SendAlarmSmsJob < ApplicationJob
  queue_as :notifications

  discard_on ActiveJob::DeserializationError, SmsDispatcher::PermanentError
  retry_on SmsDispatcher::TransientError,
           wait: :polynomially_longer, attempts: 5

  def perform(alarm_id, user_id, severity)
    alarm = Alarm.find_by(id: alarm_id)
    user  = User.find_by(id: user_id)
    return unless alarm && user&.active? && user.phone_number.present?

    SmsDispatcher.deliver(
      to: user.phone_number,
      body: AlarmSmsRenderer.render(alarm, severity)
    )
  end
end
