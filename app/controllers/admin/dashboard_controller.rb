module Admin
  class DashboardController < BaseController
    def index
      @river_basins = RiverBasin.active
      @active_alerts = Alert.active.by_severity.limit(10)
      @recent_readings = SensorReading.recent.includes(sensor: :sensor_station).limit(10)
      @sensors_online = SensorStation.online.count
      @alerts_by_severity = Alert.active.group(:severity).count
      @sensor_stations = SensorStation.where.not(location: nil).includes(:neighborhood, :river, :sensors)
    end
  end
end
