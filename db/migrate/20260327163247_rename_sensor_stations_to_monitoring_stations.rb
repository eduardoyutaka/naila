class RenameSensorStationsToMonitoringStations < ActiveRecord::Migration[8.1]
  def change
    rename_table :sensor_stations, :monitoring_stations
    rename_column :sensors, :sensor_station_id, :monitoring_station_id
  end
end
