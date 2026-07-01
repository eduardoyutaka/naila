class FloodZone < ApplicationRecord
  # Flood-inundation "manchas" for a river basin, one extent polygon per return period.
  RETURN_PERIODS = [ 5, 10, 25, 100, 200, 500 ].freeze

  belongs_to :river_basin

  validates :return_period,
    presence: true,
    inclusion: { in: RETURN_PERIODS },
    uniqueness: { scope: :river_basin_id }
end
