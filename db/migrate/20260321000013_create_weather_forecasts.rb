class CreateWeatherForecasts < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_forecasts do |t|
      t.string :source, null: false
      t.st_point :location, srid: 4326
      t.datetime :issued_at, null: false
      t.datetime :valid_from, null: false
      t.datetime :valid_until, null: false
      t.float :precipitation_mm
      t.float :precipitation_probability
      t.float :temperature_max_c
      t.float :temperature_min_c
      t.string :severity
      t.jsonb :raw_data, default: {}
      t.timestamps
    end

    add_index :weather_forecasts, :location, using: :gist
    add_index :weather_forecasts, [:source, :valid_from]
  end
end
