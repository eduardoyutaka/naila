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
    if @alarm.composite?
      evaluate_composite
    else
      evaluate_metric_or_anomaly
    end
  end

  private

  def evaluate_metric_or_anomaly
    datapoints = collect_period_datapoints
    new_state, new_severity = determine_state(datapoints)

    @alarm.update!(
      last_evaluated_at: Time.current,
      last_datapoints: datapoints
    )

    @alarm.transition_to!(
      new_state,
      reason: build_reason(datapoints, new_state, new_severity),
      datapoints: datapoints,
      severity: new_severity
    )
  end

  def evaluate_composite
    tree = CompositeRuleParser.parse(@alarm.composite_rule)

    child_states = {}
    @alarm.child_alarms.each do |child|
      child_states[child.name] = child.state
    end

    has_insufficient = @alarm.child_alarms.any?(&:insufficient_data?)
    result = tree.evaluate(child_states)

    new_state = if result
      "alarm"
    elsif has_insufficient
      "insufficient_data"
    else
      "ok"
    end

    child_summary = child_states.map { |name, state| "#{name}=#{state}" }.join(", ")
    reason = "Composite rule evaluated: #{new_state} (children: #{child_summary})"

    @alarm.update!(last_evaluated_at: Time.current)
    @alarm.transition_to!(new_state, reason: reason)
  end

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

      if @alarm.metric?
        breaching_severity = value.nil? ? nil : evaluate_threshold_bands(value)
        { "period" => i + 1, "value" => value, "breaching_severity" => breaching_severity }
      else
        breaching = value.nil? ? nil : evaluate_anomaly_breach(value)
        { "period" => i + 1, "value" => value, "breaching" => breaching }
      end
    end
  end

  # Returns the highest severity whose threshold is breached, or 0 if none.
  def evaluate_threshold_bands(value)
    @alarm.alarm_thresholds.order(severity: :desc).each do |threshold|
      return threshold.severity if threshold_breached?(value, threshold)
    end
    0
  end

  def threshold_breached?(value, threshold)
    case threshold.comparison_operator
    when "GreaterThanThreshold"           then value > threshold.threshold_value
    when "GreaterThanOrEqualToThreshold"  then value >= threshold.threshold_value
    when "LessThanThreshold"              then value < threshold.threshold_value
    when "LessThanOrEqualToThreshold"     then value <= threshold.threshold_value
    else false
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

  # Returns [new_state, severity] tuple.
  # Metric alarms: severity is 1-4 or nil. Anomaly alarms: severity is always nil.
  def determine_state(datapoints)
    if @alarm.metric?
      determine_state_metric(datapoints)
    else
      [determine_state_anomaly(datapoints), nil]
    end
  end

  def determine_state_metric(datapoints)
    missing_count = datapoints.count { |dp| dp["breaching_severity"].nil? }
    total = datapoints.size
    treatment = @alarm.missing_data_treatment || "missing"

    return ["insufficient_data", nil] if missing_count == total && treatment == "missing"

    # Find the highest severity with enough breaching periods
    [4, 3, 2, 1].each do |sev|
      effective_breaching = 0

      datapoints.each do |dp|
        if dp["breaching_severity"].nil?
          case treatment
          when "breaching"   then effective_breaching += 1
          when "notBreaching" then nil  # does not count as breach
          when "ignore", "missing" then next
          end
        else
          effective_breaching += 1 if dp["breaching_severity"] >= sev
        end
      end

      return ["alarm", sev] if effective_breaching >= @alarm.datapoints_to_alarm
    end

    ["ok", nil]
  end

  def determine_state_anomaly(datapoints)
    missing_count = datapoints.count { |dp| dp["breaching"].nil? }
    total = datapoints.size
    treatment = @alarm.missing_data_treatment || "missing"

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
        when "ignore", "missing"
          next
        end
      else
        effective_breaching += 1 if dp["breaching"]
        effective_evaluated += 1
      end
    end

    return "insufficient_data" if missing_count == total && treatment == "missing"
    effective_breaching >= @alarm.datapoints_to_alarm ? "alarm" : "ok"
  end

  def build_reason(datapoints, new_state, severity)
    values = datapoints.filter_map { |dp| dp["value"] }

    if @alarm.metric?
      breaching_count = datapoints.count { |dp| dp["breaching_severity"].to_i >= 1 }
      missing_count   = datapoints.count { |dp| dp["breaching_severity"].nil? }
    else
      breaching_count = datapoints.count { |dp| dp["breaching"] == true }
      missing_count   = datapoints.count { |dp| dp["breaching"].nil? }
    end

    case new_state
    when "alarm"
      threshold_desc = if @alarm.anomaly_detection?
        "anomaly band"
      else
        band = @alarm.alarm_thresholds.find_by(severity: severity)
        band ? "#{band.threshold_value}#{band.unit} (severity #{severity})" : "severity #{severity}"
      end
      "#{breaching_count} of #{@alarm.evaluation_periods} evaluation periods breached threshold #{threshold_desc} (values: #{values.map { |v| v&.round(2) }})"
    when "ok"
      "#{breaching_count} of #{@alarm.evaluation_periods} evaluation periods breached threshold (below #{@alarm.datapoints_to_alarm} required)"
    when "insufficient_data"
      "#{missing_count} of #{@alarm.evaluation_periods} evaluation periods had no data"
    end
  end
end
