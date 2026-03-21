class EvacuationRoute < ApplicationRecord
  belongs_to :risk_zone

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
