class Neighborhood < ApplicationRecord
  belongs_to :region
  has_many :monitoring_stations, dependent: :nullify

  validates :name, :code, presence: true
  validates :code, uniqueness: true
end
