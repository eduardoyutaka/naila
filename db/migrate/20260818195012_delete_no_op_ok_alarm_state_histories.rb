class DeleteNoOpOkAlarmStateHistories < ActiveRecord::Migration[8.1]
  def up
    # A batch of spurious rows created right after "ok" started meaning explicit severity 0:
    # current_severity was still nil from before that change, the next evaluation cycle
    # recomputed it as 0, and transition_to!'s guard logged it as a "transition" even though
    # state stayed "ok" and nothing about the alarm's real condition changed.
    execute <<~SQL
      DELETE FROM alarm_state_histories
      WHERE previous_state = 'ok' AND new_state = 'ok'
        AND previous_severity IS NULL AND new_severity = 0
    SQL
  end

  def down
    # Deleted rows can't be reconstructed (down is a no-op) — this is a one-way
    # cleanup of rows that never represented a real event.
  end
end
