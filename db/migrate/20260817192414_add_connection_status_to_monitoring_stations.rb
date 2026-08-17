class AddConnectionStatusToMonitoringStations < ActiveRecord::Migration[8.1]
  def change
    add_column :monitoring_stations, :connection_status, :string, default: "connected", null: false
    add_column :monitoring_stations, :last_successful_fetch_at, :datetime
    add_column :monitoring_stations, :last_failed_fetch_at, :datetime
  end
end
