class WeatherObservation < ApplicationRecord
  validates :source, :observed_at, presence: true

  scope :recent, -> { order(observed_at: :desc) }
  scope :by_source, ->(source) { where(source: source) }
end
