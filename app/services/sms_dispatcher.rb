class SmsDispatcher
  class Error < StandardError; end
  class TransientError < Error; end
  class PermanentError < Error; end

  class << self
    def deliver(to:, body:)
      raise ArgumentError, "phone number (to:) required" if to.to_s.strip.empty?
      raise ArgumentError, "message body required"      if body.to_s.strip.empty?

      adapter.deliver(to: to, body: body)
    end

    def adapter
      @adapter ||= default_adapter_for(Rails.env)
    end

    attr_writer :adapter

    def default_adapter_for(env)
      env.to_s == "production" ? TwilioAdapter.new : LogAdapter.new
    end
  end

  class LogAdapter
    def deliver(to:, body:)
      Rails.logger.info("[SMS:#{Rails.env}] to=#{to} body=#{body.inspect}")
    end
  end

  class TestAdapter
    attr_reader :calls

    def initialize
      @calls = []
    end

    def deliver(to:, body:)
      @calls << { to: to, body: body }
    end

    def reset!
      @calls.clear
    end
  end

  class TwilioAdapter
    PERMANENT_ERROR_RANGE = (20400..20499).freeze

    def deliver(to:, body:)
      client.messages.create(from: from_number, to: to, body: body)
    rescue Twilio::REST::RestError => e
      classify_twilio_error(e)
    end

    private

    def classify_twilio_error(error)
      if PERMANENT_ERROR_RANGE.cover?(error.code.to_i)
        raise PermanentError, "Twilio permanent error #{error.code}: #{error.message}"
      else
        raise TransientError, "Twilio transient error #{error.code}: #{error.message}"
      end
    end

    def client
      @client ||= Twilio::REST::Client.new(
        Rails.application.credentials.dig(:twilio, :account_sid),
        Rails.application.credentials.dig(:twilio, :auth_token)
      )
    end

    def from_number
      Rails.application.credentials.dig(:twilio, :from_number)
    end
  end
end
