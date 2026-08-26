module RangeParsable
  extend ActiveSupport::Concern

  private

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
