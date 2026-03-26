class BackfillSensorsAndMigrateReadings < ActiveRecord::Migration[8.1]
  def up
    # Step 1: Create one Sensor per existing SensorStation
    execute <<-SQL
      INSERT INTO sensors (sensor_station_id, sensor_type, external_id, unit, reading_type, status,
                           last_reading_at, last_reading_value, metadata, created_at, updated_at)
      SELECT
        ss.id,
        ss.station_type,
        ss.external_id || '-sensor',
        CASE ss.station_type
          WHEN 'pluviometer'     THEN 'mm'
          WHEN 'river_gauge'     THEN 'm'
          WHEN 'weather_station' THEN '°C'
        END,
        CASE ss.station_type
          WHEN 'pluviometer'     THEN 'precipitation'
          WHEN 'river_gauge'     THEN 'river_level'
          WHEN 'weather_station' THEN 'temperature'
        END,
        ss.status,
        ss.last_reading_at,
        ss.last_reading_value,
        '{}',
        NOW(),
        NOW()
      FROM sensor_stations ss
    SQL

    # Step 2: Backfill sensor_id on sensor_readings via station → sensor mapping
    execute <<-SQL
      UPDATE sensor_readings sr
      SET sensor_id = s.id
      FROM sensors s
      WHERE s.sensor_station_id = sr.sensor_station_id
    SQL

    # Step 3: Make sensor_id NOT NULL (only if all rows have been backfilled)
    # This is safe even if there are no rows
    execute "ALTER TABLE sensor_readings ALTER COLUMN sensor_id SET NOT NULL"

    # Step 4: Drop old sensor_station_id FK, indexes, and column from sensor_readings
    execute "ALTER TABLE sensor_readings DROP CONSTRAINT IF EXISTS sensor_readings_sensor_station_id_fkey"
    execute "DROP INDEX IF EXISTS index_sensor_readings_on_sensor_station_id_and_recorded_at"
    execute "DROP INDEX IF EXISTS index_sensor_readings_on_sensor_station_id"
    execute "ALTER TABLE sensor_readings DROP COLUMN sensor_station_id"

    # Step 5: Remove station_type from sensor_stations
    execute "DROP INDEX IF EXISTS index_sensor_stations_on_station_type"
    remove_column :sensor_stations, :station_type

    # Note: river_basin_id NOT NULL and uniqueness are enforced at the model level.
    # The DB constraint will be added once seeds are updated (all stations have a basin).
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
