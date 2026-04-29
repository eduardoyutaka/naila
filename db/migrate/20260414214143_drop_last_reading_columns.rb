class DropLastReadingColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :monitoring_stations, :last_reading_at, :datetime
    remove_column :monitoring_stations, :last_reading_value, :float
    remove_column :sensors, :last_reading_at, :datetime
    remove_column :sensors, :last_reading_value, :float
  end
end
