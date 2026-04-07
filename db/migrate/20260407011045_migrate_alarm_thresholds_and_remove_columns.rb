class MigrateAlarmThresholdsAndRemoveColumns < ActiveRecord::Migration[8.1]
  def up
    # 1. Copy single-threshold data from metric alarms into alarm_thresholds
    execute <<~SQL
      INSERT INTO alarm_thresholds (alarm_id, severity, comparison_operator, threshold_value, unit, created_at, updated_at)
      SELECT id, severity, comparison_operator, threshold_value, unit, NOW(), NOW()
      FROM alarms
      WHERE alarm_type = 'metric'
        AND comparison_operator IS NOT NULL
        AND threshold_value IS NOT NULL
      ON CONFLICT (alarm_id, severity) DO NOTHING
    SQL

    # 2. Populate current_severity for alarms already in alarm state
    execute <<~SQL
      UPDATE alarms
      SET current_severity = severity
      WHERE state = 'alarm' AND severity IS NOT NULL
    SQL

    # 3. Remove old single-threshold columns from alarms
    remove_column :alarms, :severity
    remove_column :alarms, :comparison_operator
    remove_column :alarms, :threshold_value
    remove_column :alarms, :unit
  end

  def down
    add_column :alarms, :severity,            :integer
    add_column :alarms, :comparison_operator, :string
    add_column :alarms, :threshold_value,     :float
    add_column :alarms, :unit,                :string

    # Restore from alarm_thresholds (take the highest severity band per alarm)
    execute <<~SQL
      UPDATE alarms a
      SET severity            = t.severity,
          comparison_operator = t.comparison_operator,
          threshold_value     = t.threshold_value,
          unit                = t.unit
      FROM (
        SELECT DISTINCT ON (alarm_id) alarm_id, severity, comparison_operator, threshold_value, unit
        FROM alarm_thresholds
        ORDER BY alarm_id, severity DESC
      ) t
      WHERE a.id = t.alarm_id
    SQL

    # Restore severity from current_severity for alarms in alarm state
    execute <<~SQL
      UPDATE alarms SET severity = current_severity WHERE state = 'alarm' AND current_severity IS NOT NULL
    SQL
  end
end
