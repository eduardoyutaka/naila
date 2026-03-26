class Alert < ApplicationRecord
  belongs_to :river_basin, optional: true
  belongs_to :neighborhood, optional: true
  belongs_to :river, optional: true
  belongs_to :alert_threshold, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :resolved_by, class_name: "User", optional: true
  has_many :alert_notifications, dependent: :destroy

  validates :title, :description, :severity, :alert_type, presence: true
  validates :severity, numericality: { in: 1..4 }
  validates :alert_type, inclusion: { in: %w[automatic manual] }

  scope :active, -> { where(status: "active") }
  scope :unacknowledged, -> { where(status: "active", acknowledged_at: nil) }
  scope :by_severity, -> { order(severity: :desc) }

  def acknowledged?
    acknowledged_at.present?
  end

  def resolved?
    status == "resolved"
  end

  def acknowledge!(user = nil)
    update!(status: "acknowledged", acknowledged_at: Time.current)
  end

  def resolve!(user = nil)
    update!(status: "resolved", resolved_by: user, resolved_at: Time.current)
  end
end
