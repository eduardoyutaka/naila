class AlarmEvaluationEngine
  def self.evaluate_all
    Alarm.enabled.metric_alarms.find_each { |alarm| evaluate_alarm(alarm) }
    Alarm.enabled.anomaly_alarms.find_each { |alarm| evaluate_alarm(alarm) }
    Alarm.enabled.composite_alarms.find_each { |alarm| evaluate_alarm(alarm) }
  end

  def self.evaluate_alarm(alarm)
    new(alarm).evaluate
  end

  def initialize(alarm)
    @alarm = alarm
  end

  def evaluate
    return if @alarm.composite?

    datapoints = collect_period_datapoints
    new_state = determine_state(datapoints)

    @alarm.update!(
      last_evaluated_at: Time.current,
      last_datapoints: datapoints
    )

    @alarm.transition_to!(new_state, reason: build_reason(datapoints, new_state), datapoints: datapoints)
  end

  private

  def collect_period_datapoints
    now = Time.current
    periods = @alarm.evaluation_periods
    period_length = @alarm.period_seconds.seconds

    (0...periods).map do |i|
      period_end = now - (i * period_length)
      period_start = period_end - period_length

      value = MetricDataCollector.collect(
        metric_name: @alarm.metric_name,
        river_basin: @alarm.river_basin,
        river: @alarm.river,
        period_start: period_start,
        period_end: period_end,
        statistic: @alarm.statistic
      )

      breaching = if value.nil?
        nil  # missing
      elsif @alarm.anomaly_detection?
        evaluate_anomaly_breach(value)
      else
        evaluate_threshold_breach(value)
      end

      { "period" => i + 1, "value" => value, "breaching" => breaching }
    end
  end

  def evaluate_threshold_breach(value)
    case @alarm.comparison_operator
    when "GreaterThanThreshold"
      value > @alarm.threshold_value
    when "GreaterThanOrEqualToThreshold"
      value >= @alarm.threshold_value
    when "LessThanThreshold"
      value < @alarm.threshold_value
    when "LessThanOrEqualToThreshold"
      value <= @alarm.threshold_value
    else
      false
    end
  end

  def evaluate_anomaly_breach(value)
    baseline = @alarm.anomaly_baseline
    return nil unless baseline

    data = baseline.baseline_data
    data = JSON.parse(data) if data.is_a?(String)
    return nil unless data.is_a?(Hash)

    now = Time.current
    hour = now.hour.to_s
    wday = now.wday.to_s
    bucket = data.dig("hourly", hour, wday)
    return nil unless bucket

    mean = bucket["mean"].to_f
    stddev = bucket["stddev"].to_f
    band = @alarm.anomaly_band_width * stddev

    value < (mean - band) || value > (mean + band)
  end

  def determine_state(datapoints)
    missing_count = datapoints.count { |dp| dp["breaching"].nil? }
    total = datapoints.size
    treatment = @alarm.missing_data_treatment || "missing"

    # Apply missing data treatment
    effective_breaching = 0
    effective_evaluated = 0

    datapoints.each do |dp|
      if dp["breaching"].nil?
        case treatment
        when "breaching"
          effective_breaching += 1
          effective_evaluated += 1
        when "notBreaching"
          effective_evaluated += 1
        when "ignore"
          # skip this period entirely
          next
        when "missing"
          # counted as missing, contributes to insufficient_data check
          next
        end
      else
        effective_breaching += 1 if dp["breaching"]
        effective_evaluated += 1
      end
    end

    # All periods missing → insufficient_data
    if missing_count == total && treatment == "missing"
      return "insufficient_data"
    end

    # Check if enough datapoints breach
    if effective_breaching >= @alarm.datapoints_to_alarm
      "alarm"
    else
      "ok"
    end
  end

  def build_reason(datapoints, new_state)
    breaching_count = datapoints.count { |dp| dp["breaching"] == true }
    missing_count = datapoints.count { |dp| dp["breaching"].nil? }
    values = datapoints.filter_map { |dp| dp["value"] }

    case new_state
    when "alarm"
      threshold_desc = if @alarm.anomaly_detection?
        "anomaly band"
      else
        "#{@alarm.threshold_value}#{@alarm.unit}"
      end
      "#{breaching_count} of #{@alarm.evaluation_periods} evaluation periods breached threshold #{threshold_desc} (values: #{values.map { |v| v&.round(2) }})"
    when "ok"
      "#{breaching_count} of #{@alarm.evaluation_periods} evaluation periods breached threshold (below #{@alarm.datapoints_to_alarm} required)"
    when "insufficient_data"
      "#{missing_count} of #{@alarm.evaluation_periods} evaluation periods had no data"
    end
  end
end
