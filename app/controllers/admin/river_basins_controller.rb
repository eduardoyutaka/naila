module Admin
  class RiverBasinsController < BaseController
    before_action :set_river_basin, only: [:show, :edit, :update, :destroy]

    def index
      @river_basins = RiverBasin.order(current_risk_level: :desc, name: :asc)
    end

    def show
      @recent_assessments = @river_basin.risk_assessments.order(assessed_at: :desc).limit(10)
      @active_alerts = @river_basin.alerts.active.by_severity
    end

    def new
      @river_basin = RiverBasin.new
    end

    def create
      @river_basin = RiverBasin.new(river_basin_params)
      authorize @river_basin
      set_geometry

      if @river_basin.save
        redirect_to admin_river_basin_path(@river_basin), notice: "Bacia hidrográfica criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      authorize @river_basin
      @river_basin.assign_attributes(river_basin_params)
      set_geometry

      if @river_basin.save
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

    def set_geometry
      geojson_str = params.dig(:river_basin, :geometry_geojson).presence
      return unless geojson_str

      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      parsed = JSON.parse(geojson_str)
      @river_basin.geometry = RGeo::GeoJSON.decode(parsed, geo_factory: factory)
    rescue JSON::ParserError, RGeo::Error::InvalidGeometry
      @river_basin.errors.add(:geometry, "inválida")
    end

    def river_basin_params
      params.require(:river_basin).permit(
        :name, :description, :area_km2, :active
      )
    end
  end
end
