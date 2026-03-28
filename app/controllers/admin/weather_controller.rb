module Admin
  class WeatherController < BaseController
    def show
      authorize :weather, :show?

      @current_conditions = WeatherObservation.current_conditions
      @recent_observations = WeatherObservation.in_last(24.hours).order(observed_at: :desc).limit(20)

      @forecasts_24h = WeatherForecast.current.valid_in_next(24.hours).ordered_timeline
      @forecasts_by_source = WeatherForecast.current.ordered_timeline.group_by(&:source)

      @data_sources = DataSource.where(source_type: "api").order(:name)

      # Forecast vs actual comparison data (last 24h)
      @past_forecasts = WeatherForecast.in_last(24.hours)
                                       .where("valid_from <= ?", Time.current)
                                       .ordered_timeline
    end
  end
end
