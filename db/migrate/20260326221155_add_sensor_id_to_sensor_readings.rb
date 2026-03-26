class AddSensorIdToSensorReadings < ActiveRecord::Migration[8.1]
  def up
    # Add nullable sensor_id column — propagates to all monthly partitions
    execute "ALTER TABLE sensor_readings ADD COLUMN sensor_id bigint"

    # Add FK to sensors
    execute "ALTER TABLE sensor_readings ADD CONSTRAINT fk_sensor_readings_sensors FOREIGN KEY (sensor_id) REFERENCES sensors(id)"

    # Add indexes
    execute "CREATE INDEX index_sensor_readings_on_sensor_id ON sensor_readings (sensor_id)"
    execute "CREATE INDEX index_sensor_readings_on_sensor_id_and_recorded_at ON sensor_readings (sensor_id, recorded_at)"
  end

  def down
    execute "ALTER TABLE sensor_readings DROP CONSTRAINT IF EXISTS fk_sensor_readings_sensors"
    execute "DROP INDEX IF EXISTS index_sensor_readings_on_sensor_id_and_recorded_at"
    execute "DROP INDEX IF EXISTS index_sensor_readings_on_sensor_id"
    execute "ALTER TABLE sensor_readings DROP COLUMN IF EXISTS sensor_id"
  end
end
