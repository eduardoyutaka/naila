class WeatherObservation < ApplicationRecord
  validates :source, :observed_at, presence: true

  scope :recent, -> { order(observed_at: :desc) }
  scope :by_source, ->(source) { where(source: source) }
  scope :in_last, ->(duration) { where("observed_at >= ?", duration.ago) }

  def self.current_conditions
    order(observed_at: :desc).first
  end
end
