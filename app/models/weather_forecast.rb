class WeatherForecast < ApplicationRecord
  validates :source, :issued_at, :valid_from, :valid_until, presence: true

  scope :current, -> { where("valid_until >= ?", Time.current) }
  scope :valid_in_next, ->(duration) { where("valid_from <= ? AND valid_until >= ?", duration.from_now, Time.current) }
  scope :by_source, ->(source) { where(source: source) }
end
