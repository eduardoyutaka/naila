class BackfillAlarmSeverityFromReasonText < ActiveRecord::Migration[8.1]
  def up
    # Pass A: the evaluation engine has embedded "(severity N)" in the reason text for every
    # "alarm" transition since multi-threshold support (154044d) — well before the
    # previous_severity/new_severity columns existed (f482399). Deterministic, not a guess
    # based on today's (possibly since-changed) thresholds.
    AlarmStateHistory.where(new_state: "alarm", new_severity: nil).find_each do |h|
      if (m = h.reason.match(/severity (\d+)/))
        h.update_column(:new_severity, m[1].to_i)
      end
    end

    # Pass B: previous_severity always equals the immediately preceding transition's
    # new_severity for the same alarm — propagate forward in evaluated_at order so a legacy
    # "alarm" row's previous_severity is recovered from Pass A's backfill too, not just "ok".
    Alarm.find_each do |alarm|
      last_severity = nil
      alarm.alarm_state_histories.order(:evaluated_at, :id).each do |h|
        h.update_column(:previous_severity, last_severity) if h.previous_severity.nil? && !last_severity.nil?
        last_severity = h.new_severity
      end
    end
  end

  def down
    # Not reversible — filled-in nils can't be distinguished from nils that were already
    # legitimately nil for a different reason. Mirrors the precedent set by
    # 20260818195012_delete_no_op_ok_alarm_state_histories.rb. Rerunning `up` is idempotent.
  end
end
