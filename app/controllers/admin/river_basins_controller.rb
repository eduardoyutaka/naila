module Admin
  class RiverBasinsController < BaseController
    skip_after_action :verify_authorized, only: :index
    after_action :verify_policy_scoped, only: :index

    before_action :set_river_basin, only: [:show, :edit, :update, :destroy]

    def index
      @river_basins = policy_scope(RiverBasin).order(current_risk_level: :desc, name: :asc)
    end

    def show
      authorize @river_basin
      @recent_assessments = @river_basin.risk_assessments.order(assessed_at: :desc).limit(10)
      @active_alarms = @river_basin.alarms.in_alarm.order(current_severity: :desc)
      @forecast_summary = WeatherForecast.aggregate_next_hours(6)
      @current_weather = WeatherObservation.current_conditions
    end

    def new
      @river_basin = RiverBasin.new
      authorize @river_basin
    end

    def create
      @river_basin = RiverBasin.new(river_basin_params)
      authorize @river_basin

      if @river_basin.save
        redirect_to admin_river_basin_path(@river_basin), notice: "Bacia hidrográfica criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @river_basin
    end

    def update
      authorize @river_basin

      if @river_basin.update(river_basin_params)
        redirect_to admin_river_basin_path(@river_basin), notice: "Bacia hidrográfica atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @river_basin
      @river_basin.destroy!
      redirect_to admin_river_basins_path, notice: "Bacia hidrográfica removida."
    end

    private

    def set_river_basin
      @river_basin = RiverBasin.find(params[:id])
    end

    def river_basin_params
      params.require(:river_basin).permit(
        :name, :description, :area_km2, :active, :geometry_geojson
      )
    end
  end
end
