class SatelliteObservation < ApplicationRecord
  validates :source, :captured_at, :observation_type, presence: true

  scope :recent, -> { order(captured_at: :desc) }
  scope :by_type, ->(type) { where(observation_type: type) }
end
