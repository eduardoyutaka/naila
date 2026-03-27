module Admin
  class MonitoringStationsController < BaseController
    before_action :set_monitoring_station, only: [:show, :edit, :update, :destroy]

    def index
      @monitoring_stations = MonitoringStation.includes(:neighborhood, :river, :sensors).order(:name)
    end

    def show
      @readings_by_type = @monitoring_station.sensor_readings
                                         .since(24.hours.ago)
                                         .order(recorded_at: :asc)
                                         .group_by(&:reading_type)

      precip_thresholds = AlertThreshold.active
                                        .where(parameter: "precipitation")
                                        .where("river_basin_id = ? OR (river_basin_id IS NULL AND river_id IS NULL)",
                                               @monitoring_station.river_basin_id)
                                        .order(:severity)

      river_id = @monitoring_station.river_id
      level_thresholds = if river_id
        AlertThreshold.active
                      .where(parameter: "river_level")
                      .where("river_id = ? OR (river_id IS NULL AND river_basin_id IS NULL)", river_id)
                      .order(:severity)
      else
        AlertThreshold.active
                      .where(parameter: "river_level", river_basin_id: nil, river_id: nil)
                      .order(:severity)
      end

      @thresholds_by_param = {
        "precipitation" => precip_thresholds.to_a,
        "river_level"   => level_thresholds.to_a
      }
    end

    def new
      @monitoring_station = MonitoringStation.new
    end

    def create
      @monitoring_station = MonitoringStation.new(monitoring_station_params)
      authorize @monitoring_station
      set_location

      if @monitoring_station.save
        redirect_to admin_monitoring_station_path(@monitoring_station), notice: "Estação criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      authorize @monitoring_station

      @monitoring_station.assign_attributes(monitoring_station_params)
      set_location

      if @monitoring_station.save
        redirect_to admin_monitoring_station_path(@monitoring_station), notice: "Estação atualizada com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @monitoring_station
      @monitoring_station.destroy!
      redirect_to admin_monitoring_stations_path, notice: "Estação removida."
    end

    private

    def set_monitoring_station
      @monitoring_station = MonitoringStation.includes(:neighborhood, :river, :sensors).find(params[:id])
    end

    def monitoring_station_params
      params.require(:monitoring_station).permit(
        :external_id, :name, :data_source, :status,
        :elevation_m, :neighborhood_id, :river_basin_id,
        :river_id, :metadata
      )
    end

    def set_location
      lat = params[:monitoring_station][:latitude].presence
      lng = params[:monitoring_station][:longitude].presence
      if lat && lng
        factory = RGeo::Geographic.spherical_factory(srid: 4326)
        @monitoring_station.location = factory.point(lng.to_f, lat.to_f)
      end
    end
  end
end
