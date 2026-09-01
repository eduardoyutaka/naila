class ReplaceAlarmMonitoringStationsWithSingleStation < ActiveRecord::Migration[8.1]
  def change
    add_reference :alarms, :monitoring_station, null: true, foreign_key: true

    # This join table was never deployed with real data — an alarm now scopes to
    # at most one station directly via alarms.monitoring_station_id instead.
    drop_table :alarm_monitoring_stations do |t|
      t.references :alarm, null: false, foreign_key: true
      t.references :monitoring_station, null: false, foreign_key: true
      t.timestamps
    end
  end
end
