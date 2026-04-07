module Admin
  class DashboardController < BaseController
    def index
      @river_basins = RiverBasin.active
      @active_alarms = Alarm.in_alarm.includes(:river_basin).order(current_severity: :desc, state_changed_at: :desc).limit(10)
      @recent_readings = SensorReading.recent.includes(sensor: :monitoring_station).limit(10)
      @sensors_online = MonitoringStation.online.count
      @alarms_by_severity = Alarm.in_alarm.group(:current_severity).count
      @monitoring_stations = MonitoringStation.where.not(location: nil).includes(:neighborhood, :river, :sensors)
      @active_alarm_severity_by_basin = Alarm.in_alarm
                                             .where.not(river_basin_id: nil)
                                             .group(:river_basin_id)
                                             .maximum(:current_severity)
      @current_weather = WeatherObservation.current_conditions
      @forecast_summary = WeatherForecast.aggregate_next_hours(6)
    end
  end
end
