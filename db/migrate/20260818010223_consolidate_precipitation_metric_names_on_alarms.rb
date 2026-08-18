class ConsolidatePrecipitationMetricNamesOnAlarms < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE alarms SET metric_name = 'precipitation'
      WHERE metric_name IN ('precipitation_1h', 'precipitation_3h', 'precipitation_24h')
    SQL

    stale = execute(<<~SQL).to_a
      SELECT id, metric_name FROM alarms
      WHERE metric_name IN ('soil_moisture', 'temperature', 'humidity', 'risk_score')
    SQL

    if stale.any?
      Rails.logger.warn(
        "[ConsolidatePrecipitationMetricNamesOnAlarms] #{stale.size} alarm(s) use a removed " \
        "metric_name and will stop evaluating real data: " \
        "#{stale.map { |r| "##{r['id']} (#{r['metric_name']})" }.join(', ')}"
      )
    end
  end

  def down
    # Granularity (1h/3h/24h) isn't recoverable from "precipitation" alone — the real
    # period already lives on period_seconds/evaluation_periods. No-op; re-running up is idempotent.
  end
end
