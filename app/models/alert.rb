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
  scope :automatic_active, -> { where(alert_type: "automatic", status: %w[active acknowledged]) }

  after_update_commit :broadcast_basin_alert_severity, if: -> {
    river_basin_id.present? && (saved_change_to_severity? || saved_change_to_status?)
  }

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

  private

  def broadcast_basin_alert_severity
    severity_by_basin = Alert.active
                             .where.not(river_basin_id: nil)
                             .group(:river_basin_id)
                             .maximum(:severity)

    Turbo::StreamsChannel.broadcast_replace_to(
      "basin_alerts",
      target: "basin-alert-severities",
      partial: "admin/dashboard/basin_alert_severities",
      locals: { severity_by_basin: severity_by_basin }
    )
  end

  public

  def update_severity!(new_severity, threshold, current_value:, risk_assessment: nil)
    return self if severity == new_severity

    history = (trigger_data["severity_changes"] || [])
    history << {
      "from" => severity,
      "to" => new_severity,
      "changed_at" => Time.current.iso8601,
      "threshold_id" => threshold.id,
      "threshold_value" => threshold.value,
      "current_value" => current_value,
      "risk_score" => risk_assessment&.risk_score
    }

    update!(
      severity: new_severity,
      alert_threshold: threshold,
      trigger_data: trigger_data.merge(
        "severity_changes" => history,
        "threshold_id" => threshold.id,
        "threshold_value" => threshold.value,
        "current_value" => current_value,
        "last_severity_change_at" => Time.current.iso8601
      )
    )
    self
  end
end
