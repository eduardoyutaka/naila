class CreateWeatherObservations < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_observations do |t|
      t.string :source, null: false
      t.string :station_code
      t.st_point :location, srid: 4326
      t.datetime :observed_at, null: false
      t.float :temperature_c
      t.float :humidity_pct
      t.float :pressure_hpa
      t.float :wind_speed_ms
      t.float :wind_direction_deg
      t.float :precipitation_mm
      t.float :precipitation_rate_mm_h
      t.string :weather_condition
      t.jsonb :raw_data, default: {}
      t.timestamps
    end

    add_index :weather_observations, :location, using: :gist
    add_index :weather_observations, [:source, :observed_at]
  end
end
