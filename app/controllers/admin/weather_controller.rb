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
      @comparison_forecasts = WeatherForecast.where(valid_from: @comparison_from..@comparison_to)
                                             .ordered_timeline

      # Section 2 — forecast bars/probability over the forecast range
      @forecasts_in_range = WeatherForecast.where(valid_from: @forecast_from..@forecast_to).ordered_timeline

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
