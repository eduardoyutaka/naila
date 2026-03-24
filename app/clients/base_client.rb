class BaseClient
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 15
  MAX_RETRIES = 3
  RETRY_INTERVAL = 0.5

  attr_reader :data_source

  def initialize(data_source)
    @data_source = data_source
  end

  def connection
    @connection ||= Faraday.new(url: data_source.base_url) do |f|
      f.request :retry, max: MAX_RETRIES, interval: RETRY_INTERVAL,
                         backoff_factor: 2, exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError]
      f.response :json, content_type: /\bjson$/
      f.options.open_timeout = OPEN_TIMEOUT
      f.options.timeout = READ_TIMEOUT
    end
  end

  def fetch
    if data_source.status == "offline" && !data_source.can_retry?
      Rails.logger.info("[#{self.class.name}] Skipping fetch — data source #{data_source.name} is offline")
      return nil
    end

    response = yield(connection)

    if response.success?
      data_source.record_success!
      response
    else
      Rails.logger.warn("[#{self.class.name}] HTTP #{response.status} from #{data_source.name}")
      data_source.record_failure!
      nil
    end
  rescue Faraday::Error, Timeout::Error, JSON::ParserError => e
    Rails.logger.error("[#{self.class.name}] Error fetching #{data_source.name}: #{e.message}")
    data_source.record_failure!
    nil
  end
end
