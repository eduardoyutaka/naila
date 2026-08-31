# Explicit "this station feeds this basin's metrics/alarms" configuration —
# distinct from MonitoringStation#river_basin_id, which is the station's home/
# ownership basin (used for admin display and cascade-delete). A single station
# can be configured for more than one basin here; MetricDataCollector reads
# through this join, not the home FK, to decide which sensors feed an alarm.
class RiverBasinMonitoringStation < ApplicationRecord
  belongs_to :river_basin
  belongs_to :monitoring_station

  validates :monitoring_station_id, uniqueness: { scope: :river_basin_id }
end
