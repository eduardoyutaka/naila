module Admin
  class SensorStationsController < BaseController
    before_action :set_sensor_station, only: [:show, :edit, :update, :destroy]

    def index
      @sensor_stations = SensorStation.includes(:neighborhood, :river).order(:name)
    end

    def show
      @readings_by_type = @sensor_station.sensor_readings
                                         .since(24.hours.ago)
                                         .order(recorded_at: :asc)
                                         .group_by(&:reading_type)
    end

    def new
      @sensor_station = SensorStation.new
    end

    def create
      @sensor_station = SensorStation.new(sensor_station_params)
      authorize @sensor_station
      set_location

      if @sensor_station.save
        redirect_to admin_sensor_station_path(@sensor_station), notice: "Estação criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      authorize @sensor_station

      @sensor_station.assign_attributes(sensor_station_params)
      set_location

      if @sensor_station.save
        redirect_to admin_sensor_station_path(@sensor_station), notice: "Estação atualizada com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @sensor_station
      @sensor_station.destroy!
      redirect_to admin_sensor_stations_path, notice: "Estação removida."
    end

    private

    def set_sensor_station
      @sensor_station = SensorStation.includes(:neighborhood, :river).find(params[:id])
    end

    def sensor_station_params
      params.require(:sensor_station).permit(
        :external_id, :name, :station_type, :data_source, :status,
        :elevation_m, :neighborhood_id, :river_basin_id,
        :river_id, :metadata
      )
    end

    def set_location
      lat = params[:sensor_station][:latitude].presence
      lng = params[:sensor_station][:longitude].presence
      if lat && lng
        factory = RGeo::Geographic.spherical_factory(srid: 4326)
        @sensor_station.location = factory.point(lng.to_f, lat.to_f)
      end
    end
  end
end
