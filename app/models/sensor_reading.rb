class SensorReading < ApplicationRecord
  belongs_to :sensor
  delegate :monitoring_station, to: :sensor

  validates :value, :unit, :reading_type, :recorded_at, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
  scope :since, ->(time) { where("recorded_at >= ?", time) }
  scope :by_type, ->(type) { where(reading_type: type) }
end
