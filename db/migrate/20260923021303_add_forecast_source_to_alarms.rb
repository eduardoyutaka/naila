class AddForecastSourceToAlarms < ActiveRecord::Migration[8.1]
  def change
    add_column :alarms, :forecast_source, :string
  end
end
