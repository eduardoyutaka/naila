class AddUniquenessIndexesForDeduplication < ActiveRecord::Migration[8.1]
  def change
    remove_index :weather_observations, [:source, :observed_at]
    add_index :weather_observations, [:source, :station_code, :observed_at],
              unique: true, name: "idx_weather_obs_dedup"

    remove_index :weather_forecasts, [:source, :valid_from]
    add_index :weather_forecasts, [:source, :valid_from, :valid_until],
              unique: true, name: "idx_weather_fc_dedup"
  end
end
