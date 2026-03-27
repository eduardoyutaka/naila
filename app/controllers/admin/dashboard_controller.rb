module Admin
  class DashboardController < BaseController
    def index
      @river_basins = RiverBasin.active
      @active_alerts = Alert.active.by_severity.limit(10)
      @recent_readings = SensorReading.recent.includes(sensor: :monitoring_station).limit(10)
      @sensors_online = MonitoringStation.online.count
      @alerts_by_severity = Alert.active.group(:severity).count
      @monitoring_stations = MonitoringStation.where.not(location: nil).includes(:neighborhood, :river, :sensors)
      @active_alert_severity_by_basin = Alert.active
                                             .where.not(river_basin_id: nil)
                                             .group(:river_basin_id)
                                             .maximum(:severity)
    end
  end
end
