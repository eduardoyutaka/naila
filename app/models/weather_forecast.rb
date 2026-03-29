class WeatherForecast < ApplicationRecord
  validates :source, :issued_at, :valid_from, :valid_until, presence: true

  scope :current, -> { where("valid_until >= ?", Time.current) }
  scope :valid_in_next, ->(duration) { where("valid_from <= ? AND valid_until >= ?", duration.from_now, Time.current) }
  scope :by_source, ->(source) { where(source: source) }
  scope :ordered_timeline, -> { order(valid_from: :asc) }
  scope :in_last, ->(duration) { where("issued_at >= ?", duration.ago) }

  def self.aggregate_next_hours(n)
    forecasts = current.valid_in_next(n.hours)
    {
      total_precipitation_mm: forecasts.sum(:precipitation_mm).round(1),
      max_precipitation_mm: forecasts.maximum(:precipitation_mm) || 0.0,
      max_probability: forecasts.maximum(:precipitation_probability) || 0.0
    }
  end

  def self.map_timeline(hours: 72)
    current.valid_in_next(hours.hours).ordered_timeline.map do |f|
      raw = f.raw_data.is_a?(String) ? (JSON.parse(f.raw_data) rescue {}) : (f.raw_data || {})
      weather_codes = raw["weather_codes"] || []

      {
        valid_from: f.valid_from.iso8601,
        valid_until: f.valid_until.iso8601,
        precipitation_mm: f.precipitation_mm.to_f.round(1),
        precipitation_probability: f.precipitation_probability.to_f.round(0),
        temperature_max_c: f.temperature_max_c&.round(1),
        temperature_min_c: f.temperature_min_c&.round(1),
        weather_code: dominant_weather_code(weather_codes)
      }
    end
  end

  def self.dominant_weather_code(codes)
    return 0 if codes.empty?
    codes.max_by { |c| wmo_severity(c) }
  end

  def self.wmo_severity(code)
    case code
    when 95..99 then 5
    when 80..82 then 4
    when 61..67 then 3
    when 51..57 then 2
    when 71..77 then 2
    when 45..48 then 1
    else 0
    end
  end

  private_class_method :dominant_weather_code, :wmo_severity

end
