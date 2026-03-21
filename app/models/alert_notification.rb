class AlertNotification < ApplicationRecord
  belongs_to :alert

  validates :channel, :status, presence: true
  validates :channel, inclusion: { in: %w[websocket sms push email civil_defense] }

  scope :pending, -> { where(status: "pending") }
  scope :sent, -> { where(status: "sent") }
  scope :failed, -> { where(status: "failed") }
end
