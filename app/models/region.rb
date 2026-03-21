class Region < ApplicationRecord
  has_many :neighborhoods, dependent: :destroy

  validates :name, :code, presence: true
  validates :code, uniqueness: true
end
