class BackfillMonitoringStationOnPrecipitationAlarms < ActiveRecord::Migration[8.1]
  # Precipitation alarms now require a single monitoring_station (pooling multiple
  # stations' readings via Sum/Average isn't a meaningful accumulated value). Existing
  # alarms whose basin has exactly one configured station get it assigned automatically;
  # anything ambiguous (0 or 2+ configured stations) is left alone and reported instead
  # of guessed at — an operator needs to pick deliberately.
  def up
    fixed = 0
    flagged = []

    Alarm.where(metric_name: "precipitation", monitoring_station_id: nil).find_each do |alarm|
      configured = alarm.river_basin&.configured_monitoring_stations || MonitoringStation.none

      if configured.count == 1
        alarm.update_column(:monitoring_station_id, configured.first.id)
        fixed += 1
      else
        flagged << alarm.id
      end
    end

    say "Backfilled monitoring_station_id on #{fixed} alarm(s)."
    say "Flagged #{flagged.size} alarm(s) needing manual review: #{flagged.join(', ')}" if flagged.any?
  end

  def down
    # Not reversible — can't distinguish a backfilled value from one a human later set
    # on purpose. Mirrors the precedent set by other data-only migrations in this app.
  end
end
