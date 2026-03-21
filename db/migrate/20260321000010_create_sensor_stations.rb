class CreateSensorStations < ActiveRecord::Migration[8.0]
  def change
    create_table :sensor_stations do |t|
      t.string :external_id, null: false
      t.string :name, null: false
      t.string :station_type, null: false
      t.string :data_source, null: false
      t.st_point :location, srid: 4326
      t.float :elevation_m
      t.references :neighborhood, foreign_key: true
      t.references :drainage_basin, foreign_key: true
      t.references :river, foreign_key: true, null: true
      t.string :status, default: "active"
      t.datetime :last_reading_at
      t.float :last_reading_value
      t.jsonb :metadata, default: {}
      t.string :api_token_digest
      t.timestamps
    end

    add_index :sensor_stations, :location, using: :gist
    add_index :sensor_stations, [:external_id, :data_source], unique: true
    add_index :sensor_stations, :station_type
    add_index :sensor_stations, :status
  end
end
