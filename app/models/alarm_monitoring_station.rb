# Narrows which of an alarm's basin's configured stations this specific alarm
# actually reads. An alarm with no rows here reads ALL of its basin's
# configured_monitoring_stations (see Alarm#effective_monitoring_stations) —
# this table is purely an opt-in narrowing, never a way to attach a station
# that isn't already configured for the basin (see Alarm's validation).
class AlarmMonitoringStation < ApplicationRecord
  belongs_to :alarm
  belongs_to :monitoring_station

  validates :monitoring_station_id, uniqueness: { scope: :alarm_id }
end
