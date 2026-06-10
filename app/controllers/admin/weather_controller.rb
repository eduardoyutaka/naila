module Admin
  class WeatherController < BaseController
    def show
      authorize :weather, :show?

      @current_conditions = WeatherObservation.current_conditions

      @comparison_from, @comparison_to =
        parse_range(params[:comparison], default_from: 24.hours.ago, default_to: Time.current)
      @forecast_from, @forecast_to =
        parse_range(params[:forecast], default_from: Time.current, default_to: 24.hours.from_now)

      # Section 4 — observed precipitation vs forecast over the comparison range
      @observations_in_range = WeatherObservation.where(observed_at: @comparison_from..@comparison_to)
                                                 .order(observed_at: :asc)
      @comparison_forecasts = WeatherForecast.overlapping(@comparison_from, @comparison_to).ordered_timeline

      # Section 2 — forecast bars/probability over the forecast range
      @forecasts_in_range = WeatherForecast.overlapping(@forecast_from, @forecast_to).ordered_timeline

      # Bound each picker to the window where data actually exists, so the range
      # can't roam into permanently-empty time.
      @forecast_bounds = [ WeatherForecast.minimum(:valid_from), WeatherForecast.maximum(:valid_until) ]
      @comparison_bounds = [
        [ WeatherObservation.minimum(:observed_at), WeatherForecast.minimum(:valid_from) ].compact.min,
        [ WeatherObservation.maximum(:observed_at), WeatherForecast.maximum(:valid_until) ].compact.max
      ]

      @data_sources = DataSource.where(source_type: "api").order(:name)
    end

    private

    # Parses a `{ from:, to: }` scope into an ordered [from, to] pair,
    # falling back to defaults and tolerating reversed bounds.
    def parse_range(scoped, default_from:, default_to:)
      from = parse_time(scoped&.dig(:from)) || default_from
      to   = parse_time(scoped&.dig(:to))   || default_to
      from > to ? [ to, from ] : [ from, to ]
    end

    def parse_time(value)
      value.present? ? Time.zone.parse(value.to_s) : nil
    rescue ArgumentError
      nil
    end
  end
end
