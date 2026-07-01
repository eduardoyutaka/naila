module Admin
  class WeatherController < BaseController
    def show
      authorize :weather, :show?

      @current_conditions = WeatherObservation.current_conditions

      # Bound each picker to the window where data actually exists, so the range
      # can't roam into permanently-empty time. Computed first so the defaults
      # below can be clamped inside these bounds — otherwise a now-anchored
      # default can fall outside [min, max] and the datetime input silently
      # blocks the "Aplicar" submit.
      @forecast_bounds = [ WeatherForecast.minimum(:valid_from), WeatherForecast.maximum(:valid_until) ]
      @comparison_bounds = [
        [ WeatherObservation.minimum(:observed_at), WeatherForecast.minimum(:valid_from) ].compact.min,
        [ WeatherObservation.maximum(:observed_at), WeatherForecast.maximum(:valid_until) ].compact.max
      ]

      @comparison_from, @comparison_to =
        parse_range(params[:comparison], default_from: 24.hours.ago, default_to: Time.current, bounds: @comparison_bounds)
      @forecast_from, @forecast_to =
        parse_range(params[:forecast], default_from: Time.current, default_to: 24.hours.from_now, bounds: @forecast_bounds)

      # Section 4 — observed precipitation vs forecast over the comparison range
      @observations_in_range = WeatherObservation.where(observed_at: @comparison_from..@comparison_to)
                                                 .order(observed_at: :asc)
      @comparison_forecasts = WeatherForecast.overlapping(@comparison_from, @comparison_to).ordered_timeline

      # Section 3 — forecast bars/probability over the forecast range, scoped to
      # the selected provider (with a stable default so it never flips on its own).
      @forecasts_in_range = WeatherForecast.overlapping(@forecast_from, @forecast_to).ordered_timeline
      @forecast_source = resolve_forecast_source(params[:forecast_source], @forecasts_in_range)

      @data_sources = DataSource.where(source_type: "api").order(:name)
    end

    private

    # Resolves the forecast provider to display: an explicit valid choice, else
    # the first configured provider that actually has data in range, else the
    # first configured provider (deterministic regardless of what data exists).
    def resolve_forecast_source(requested, forecasts)
      return requested if requested.in?(WeatherForecast::FORECAST_SOURCES)

      available = forecasts.map(&:source)
      WeatherForecast::FORECAST_SOURCES.find { |source| available.include?(source) } ||
        WeatherForecast::FORECAST_SOURCES.first
    end

    # Parses a `{ from:, to: }` scope into an ordered [from, to] pair. Falls back
    # to defaults (clamped inside `bounds`) and tolerates reversed bounds. Only
    # the defaults are clamped — an explicit range is honoured as-is so a
    # deliberately out-of-window query still resolves to the empty state.
    def parse_range(scoped, default_from:, default_to:, bounds: nil)
      scoped = nil unless scoped.respond_to?(:dig)
      from = parse_time(scoped&.dig(:from)) || clamp(default_from, bounds)
      to   = parse_time(scoped&.dig(:to))   || clamp(default_to, bounds)
      from > to ? [ to, from ] : [ from, to ]
    end

    def clamp(time, bounds)
      return time unless bounds&.all?
      time.clamp(bounds[0], bounds[1])
    end

    def parse_time(value)
      value.present? ? Time.zone.parse(value.to_s) : nil
    rescue ArgumentError
      nil
    end
  end
end
