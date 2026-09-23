class BackfillMissingPreviousSeverityOnOkAlarmStateHistories < ActiveRecord::Migration[8.1]
  def up
    # Mirrors 20260818193850's backfill of new_severity, for the previous_severity side —
    # "ok" has always meant severity 0 (Vigilância). These rows predate the transition_to!
    # logic that assigns 0 explicitly and were left with previous_severity: nil, which made
    # e.g. a legacy "ok -> alarm" row render as "Dados Insuficientes -> Dados Insuficientes".
    execute <<~SQL
      UPDATE alarm_state_histories
      SET previous_severity = 0
      WHERE previous_state = 'ok' AND previous_severity IS NULL
    SQL
  end

  def down
    execute <<~SQL
      UPDATE alarm_state_histories
      SET previous_severity = NULL
      WHERE previous_state = 'ok' AND previous_severity = 0
    SQL
  end
end
