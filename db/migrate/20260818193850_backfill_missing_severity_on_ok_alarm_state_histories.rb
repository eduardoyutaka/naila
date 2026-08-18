class BackfillMissingSeverityOnOkAlarmStateHistories < ActiveRecord::Migration[8.1]
  def up
    # "ok" has always meant severity 0 (Vigilância), never "unknown" — these rows predate the
    # transition_to! logic that assigns 0 explicitly and were left with new_severity: nil.
    execute <<~SQL
      UPDATE alarm_state_histories
      SET new_severity = 0
      WHERE new_state = 'ok' AND new_severity IS NULL
    SQL
  end

  def down
    execute <<~SQL
      UPDATE alarm_state_histories
      SET new_severity = NULL
      WHERE new_state = 'ok' AND new_severity = 0
    SQL
  end
end
