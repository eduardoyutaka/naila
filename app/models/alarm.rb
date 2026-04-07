class Alarm < ApplicationRecord
  STATES = %w[ok alarm insufficient_data].freeze
  ALARM_TYPES = %w[metric anomaly_detection composite].freeze
  STATISTICS = %w[Average Sum Minimum Maximum SampleCount].freeze
  COMPARISON_OPERATORS = %w[
    GreaterThanThreshold LessThanThreshold
    GreaterThanOrEqualToThreshold LessThanOrEqualToThreshold
  ].freeze
  MISSING_DATA_TREATMENTS = %w[missing notBreaching breaching ignore].freeze

  # ── Associations ──

  belongs_to :river_basin, optional: true
  belongs_to :river, optional: true
  belongs_to :anomaly_baseline, optional: true

  has_many :alarm_thresholds, dependent: :destroy
  has_many :alarm_actions, dependent: :destroy
  has_many :alarm_state_histories, dependent: :destroy
  has_many :composite_alarm_children, foreign_key: :composite_alarm_id, dependent: :destroy
  has_many :child_alarms, through: :composite_alarm_children
  has_many :parent_composite_links, class_name: "CompositeAlarmChild", foreign_key: :child_alarm_id, dependent: :destroy

  accepts_nested_attributes_for :alarm_thresholds, allow_destroy: true, reject_if: :all_blank

  # ── Validations ──

  validates :name, presence: true
  validates :alarm_type, presence: true, inclusion: { in: ALARM_TYPES }
  validates :state, presence: true, inclusion: { in: STATES }
  validates :severity, presence: true, numericality: { in: 1..4 }

  # Metric alarm validations
  with_options if: :metric_or_anomaly? do
    validates :metric_name, presence: true
    validates :statistic, presence: true, inclusion: { in: STATISTICS }
    validates :period_seconds, presence: true, numericality: { greater_than: 0 }
    validates :evaluation_periods, presence: true, numericality: { greater_than: 0 }
    validates :datapoints_to_alarm, presence: true, numericality: { greater_than: 0 }
  end

  with_options if: :metric? do
    validates :comparison_operator, presence: true, inclusion: { in: COMPARISON_OPERATORS }
    validates :threshold_value, presence: true
  end

  validates :missing_data_treatment, inclusion: { in: MISSING_DATA_TREATMENTS }, allow_nil: true
  validate :datapoints_cannot_exceed_evaluation_periods, if: -> { datapoints_to_alarm.present? && evaluation_periods.present? }
  validate :metric_alarm_requires_threshold_band, if: :metric?

  # Composite alarm validations
  validates :composite_rule, presence: true, if: :composite?

  # Anomaly detection validations
  with_options if: :anomaly_detection? do
    validates :anomaly_band_width, presence: true, numericality: { greater_than: 0 }
  end

  # ── Scopes ──

  scope :enabled, -> { where(enabled: true) }
  scope :metric_alarms, -> { where(alarm_type: "metric") }
  scope :anomaly_alarms, -> { where(alarm_type: "anomaly_detection") }
  scope :composite_alarms, -> { where(alarm_type: "composite") }
  scope :in_alarm, -> { where(state: "alarm") }
  scope :by_state, ->(s) { where(state: s) }

  # ── State helpers ──

  def ok?
    state == "ok"
  end

  def alarm?
    state == "alarm"
  end

  def insufficient_data?
    state == "insufficient_data"
  end

  # ── Type helpers ──

  def metric?
    alarm_type == "metric"
  end

  def anomaly_detection?
    alarm_type == "anomaly_detection"
  end

  def composite?
    alarm_type == "composite"
  end

  # ── State machine ──

  def transition_to!(new_state, reason:, datapoints: [], severity: nil)
    new_severity = new_state == "alarm" ? severity : nil

    # Severity-only change while already in alarm state
    if state == "alarm" && new_state == "alarm" && current_severity != new_severity
      update!(current_severity: new_severity, last_evaluated_at: Time.current, state_reason: reason)
      alarm_state_histories.create!(
        previous_state: "alarm",
        new_state: "alarm",
        reason: reason,
        datapoints: datapoints,
        evaluated_at: Time.current
      )
      AlarmActionExecutor.execute(self, "alarm")
      return
    end

    return if state == new_state && current_severity == new_severity

    old_state = state
    update!(state: new_state, current_severity: new_severity,
            state_changed_at: Time.current, state_reason: reason)
    alarm_state_histories.create!(
      previous_state: old_state,
      new_state: new_state,
      reason: reason,
      datapoints: datapoints,
      evaluated_at: Time.current
    )
    AlarmActionExecutor.execute(self, new_state)
  end

  after_update_commit :broadcast_basin_alarm_severity, if: -> {
    river_basin_id.present? && (saved_change_to_state? || saved_change_to_current_severity?)
  }

  private

  def broadcast_basin_alarm_severity
    severity_by_basin = Alarm.in_alarm
                             .where.not(river_basin_id: nil)
                             .group(:river_basin_id)
                             .maximum(:current_severity)
    Turbo::StreamsChannel.broadcast_replace_to(
      "basin_alarms",
      target: "basin-alarm-severities",
      partial: "admin/dashboard/basin_alarm_severities",
      locals: { severity_by_basin: severity_by_basin }
    )
  end

  def metric_or_anomaly?
    metric? || anomaly_detection?
  end

  def datapoints_cannot_exceed_evaluation_periods
    if datapoints_to_alarm > evaluation_periods
      errors.add(:datapoints_to_alarm, "must be less than or equal to evaluation_periods")
    end
  end

  def metric_alarm_requires_threshold_band
    if alarm_thresholds.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "deve ter ao menos uma faixa de limiar")
    end
  end
end
