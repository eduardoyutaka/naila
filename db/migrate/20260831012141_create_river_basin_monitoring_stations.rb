class CreateRiverBasinMonitoringStations < ActiveRecord::Migration[8.1]
  def change
    create_table :river_basin_monitoring_stations do |t|
      t.references :river_basin, null: false, foreign_key: true
      t.references :monitoring_station, null: false, foreign_key: true

      t.timestamps
    end

    add_index :river_basin_monitoring_stations, [ :river_basin_id, :monitoring_station_id ],
              unique: true, name: "idx_basin_station_uniqueness"

    # Backfill: every existing station's home river_basin_id becomes its first
    # "configured" station, so no alarm's data source changes when this ships.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO river_basin_monitoring_stations (river_basin_id, monitoring_station_id, created_at, updated_at)
          SELECT river_basin_id, id, NOW(), NOW()
          FROM monitoring_stations
          WHERE river_basin_id IS NOT NULL
        SQL
      end
    end
  end
end
