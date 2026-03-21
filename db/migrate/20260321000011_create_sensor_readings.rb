# Raw SQL is used here because PostgreSQL table partitioning (PARTITION BY RANGE)
# is not supported by the Rails migration DSL.
class CreateSensorReadings < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE TABLE sensor_readings (
        id bigserial,
        sensor_station_id bigint NOT NULL,
        recorded_at timestamptz NOT NULL,
        value float NOT NULL,
        unit varchar(20) NOT NULL,
        reading_type varchar(30) NOT NULL,
        quality_flag varchar(10) DEFAULT 'ok',
        raw_payload jsonb DEFAULT '{}',
        created_at timestamptz NOT NULL DEFAULT now(),
        PRIMARY KEY (id, recorded_at)
      ) PARTITION BY RANGE (recorded_at);
    SQL

    # Create monthly partitions for current year + next year
    (Date.today.year..(Date.today.year + 1)).each do |year|
      (1..12).each do |month|
        start_date = Date.new(year, month, 1)
        end_date = start_date.next_month
        partition_name = "sensor_readings_#{year}_#{format('%02d', month)}"
        execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{partition_name} PARTITION OF sensor_readings
          FOR VALUES FROM ('#{start_date}') TO ('#{end_date}');
        SQL
      end
    end

    add_index :sensor_readings, :sensor_station_id
    add_index :sensor_readings, [:sensor_station_id, :recorded_at]
    add_index :sensor_readings, :reading_type
    add_foreign_key :sensor_readings, :sensor_stations
  end

  def down
    drop_table :sensor_readings
  end
end
