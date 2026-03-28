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
end
