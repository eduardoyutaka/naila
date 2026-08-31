class CreateAlarmMonitoringStations < ActiveRecord::Migration[8.1]
  def change
    create_table :alarm_monitoring_stations do |t|
      t.references :alarm, null: false, foreign_key: true
      t.references :monitoring_station, null: false, foreign_key: true

      t.timestamps
    end

    add_index :alarm_monitoring_stations, [ :alarm_id, :monitoring_station_id ],
              unique: true, name: "idx_alarm_station_uniqueness"
  end
end
