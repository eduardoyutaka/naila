class EvacuationRoute < ApplicationRecord
  belongs_to :river_basin

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
