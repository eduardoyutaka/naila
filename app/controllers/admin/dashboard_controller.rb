module Admin
  class DashboardController < BaseController
    skip_after_action :verify_authorized, only: :index

    def index
      @river_basins = RiverBasin.active
      @active_alarms = Alarm.in_alarm.includes(:river_basin).order(current_severity: :desc, state_changed_at: :desc).limit(10)
      @recent_readings = SensorReading.recent.includes(sensor: :monitoring_station).limit(10)
      # current_severity is now explicit (0 for "ok"/Vigilância, 1..4 for "alarm") — one
      # query covers the whole 0..4 bucket set, no more hand-rolled synthesis of bucket 0.
      @alarms_by_severity = Alarm.enabled.evaluated.group(:current_severity).count
      @active_sensors = Sensor.online.count
      @total_sensors = Sensor.count
      @monitoring_stations = MonitoringStation.where.not(location: nil).includes(:neighborhood, :river, :sensors)
      @active_alarm_severity_by_basin = Alarm.max_severity_by_basin
      @flood_zones = FloodZone.order(:return_period)
      @current_weather = WeatherObservation.current_conditions
      @forecast_summary = WeatherForecast.aggregate_next_hours(6)
    end
  end
end
