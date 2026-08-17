class BackfillUnknownConnectionStatusOnMonitoringStations < ActiveRecord::Migration[8.1]
  def up
    change_column_default :monitoring_stations, :connection_status, from: "connected", to: "unknown"

    # Stations that were seeded/created before any fetch was ever attempted
    # against them were defaulted to "connected" — a false positive. Reclassify
    # them as "unknown" since we have no evidence either way.
    execute <<~SQL
      UPDATE monitoring_stations
      SET connection_status = 'unknown'
      WHERE connection_status = 'connected'
        AND last_successful_fetch_at IS NULL
        AND last_failed_fetch_at IS NULL
    SQL
  end

  def down
    change_column_default :monitoring_stations, :connection_status, from: "unknown", to: "connected"

    execute <<~SQL
      UPDATE monitoring_stations
      SET connection_status = 'connected'
      WHERE connection_status = 'unknown'
    SQL
  end
end
