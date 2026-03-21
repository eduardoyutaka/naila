class WeatherForecast < ApplicationRecord
  validates :source, :issued_at, :valid_from, :valid_until, presence: true

  scope :current, -> { where("valid_until >= ?", Time.current) }
  scope :by_source, ->(source) { where(source: source) }
end
