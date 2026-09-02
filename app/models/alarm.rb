class Alarm < ApplicationRecord
  STATES = %w[ok alarm insufficient_data].freeze
  ALARM_TYPES = %w[metric].freeze
  STATISTICS = %w[Average Sum Minimum Maximum SampleCount].freeze
  COMPARISON_OPERATORS = %w[
    GreaterThanThreshold LessThanThreshold
    GreaterThanOrEqualToThreshold LessThanOrEqualToThreshold
  ].freeze
  MISSING_DATA_TREATMENTS = %w[missing notBreaching breaching ignore].freeze

  # ── Associations ──

  belongs_to :river_basin, optional: true
  belongs_to :river, optional: true

  has_many :alarm_thresholds, dependent: :destroy
  has_many :alarm_actions, dependent: :destroy
  has_many :alarm_state_histories, dependent: :destroy

  # Optional narrowing to a single one of the basin's configured stations —
  # see #effective_monitoring_stations.
  belongs_to :monitoring_station, optional: true

  accepts_nested_attributes_for :alarm_thresholds, allow_destroy: true, reject_if: :all_blank

  # ── Validations ──

  validates :name, presence: true
  validates :alarm_type, presence: true, inclusion: { in: ALARM_TYPES }
  validates :state, presence: true, inclusion: { in: STATES }

  validates :metric_name, presence: true, inclusion: { in: MetricDataCollector::SUPPORTED_METRICS }
  validates :statistic, presence: true, inclusion: { in: STATISTICS }
  validates :period_seconds, presence: true, numericality: { greater_than: 0 }
  validates :evaluation_periods, presence: true, numericality: { greater_than: 0 }
  validates :datapoints_to_alarm, presence: true, numericality: { greater_than: 0 }
  validates :missing_data_treatment, inclusion: { in: MISSING_DATA_TREATMENTS }, allow_nil: true
  validate :datapoints_cannot_exceed_evaluation_periods, if: -> { datapoints_to_alarm.present? && evaluation_periods.present? }
  validate :metric_alarm_requires_threshold_band
  validate :monitoring_station_must_be_configured_for_basin

  # ── Scopes ──

  scope :enabled, -> { where(enabled: true) }
  scope :metric_alarms, -> { where(alarm_type: "metric") }
  scope :in_alarm, -> { where(state: "alarm") }
  scope :by_state, ->(s) { where(state: s) }
  scope :by_enabled, ->(val) { where(enabled: val) }
  scope :search_by_name, ->(term) { where("name ILIKE ?", "%#{sanitize_sql_like(term)}%") if term.present? }
  # Alarms with a meaningful current_severity — "ok" (0, Vigilância) or "alarm" (1..4).
  # Excludes "insufficient_data", whose current_severity is always nil (genuinely unknown,
  # not "confirmed calm").
  scope :evaluated, -> { where(state: %w[ok alarm]) }

  def self.max_severity_by_basin
    evaluated.where.not(river_basin_id: nil).group(:river_basin_id).maximum(:current_severity)
  end

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

  # The stations this alarm actually reads. An explicit monitoring_station narrows
  # down to just that one; with none selected, it falls back to every station
  # configured for the alarm's basin (see RiverBasin#configured_monitoring_stations) —
  # the same basin-wide behavior alarms had before scoping existed.
  def effective_monitoring_stations
    return [ monitoring_station ] if monitoring_station
    river_basin&.configured_monitoring_stations || MonitoringStation.none
  end

  # ── State machine ──

  def transition_to!(new_state, reason:, datapoints: [], severity: nil)
    new_severity = case new_state
                   when "alarm" then severity
                   when "ok"    then 0 # Vigilância — explicit, not the absence of a value
                   else nil            # insufficient_data — genuinely unknown, not Vigilância
                   end

    # Severity-only change while already in alarm state
    if state == "alarm" && new_state == "alarm" && current_severity != new_severity
      previous_severity = current_severity
      previous_peak = episode_peak_severity
      new_peak = [ previous_peak.to_i, new_severity.to_i ].max
      update!(current_severity: new_severity, last_evaluated_at: Time.current, state_reason: reason,
              episode_peak_severity: new_peak)
      alarm_state_histories.create!(
        previous_state: "alarm",
        new_state: "alarm",
        previous_severity: previous_severity,
        new_severity: new_severity,
        reason: reason,
        datapoints: datapoints,
        evaluated_at: Time.current
      )
      AlarmActionExecutor.execute(self, "alarm", previous_severity: previous_severity, previous_peak: previous_peak)
      return
    end

    return if state == new_state && current_severity == new_severity

    old_state = state
    previous_severity = current_severity
    previous_peak = episode_peak_severity
    # The episode's peak only exists while firing — entering/staying in "alarm" raises it
    # (never lowers it), any other state ends the episode and clears it.
    new_peak = new_state == "alarm" ? [ previous_peak.to_i, new_severity.to_i ].max : nil
    update!(state: new_state, current_severity: new_severity,
            state_changed_at: Time.current, state_reason: reason, episode_peak_severity: new_peak)
    alarm_state_histories.create!(
      previous_state: old_state,
      new_state: new_state,
      previous_severity: previous_severity,
      new_severity: new_severity,
      reason: reason,
      datapoints: datapoints,
      evaluated_at: Time.current
    )
    AlarmActionExecutor.execute(self, new_state, previous_severity: previous_severity, previous_peak: previous_peak)
  end

  after_update_commit :broadcast_basin_alarm_severity, if: -> {
    river_basin_id.present? && (saved_change_to_state? || saved_change_to_current_severity?)
  }

  private

  def broadcast_basin_alarm_severity
    severity_by_basin = Alarm.max_severity_by_basin
    Turbo::StreamsChannel.broadcast_replace_to(
      "basin_alarms",
      target: "basin-alarm-severities",
      partial: "admin/dashboard/basin_alarm_severities",
      locals: { severity_by_basin: severity_by_basin }
    )
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

  def monitoring_station_must_be_configured_for_basin
    return if monitoring_station.nil?

    configured_ids = river_basin ? river_basin.configured_monitoring_station_ids : []
    unless configured_ids.include?(monitoring_station.id)
      errors.add(:monitoring_station, "deve pertencer às estações configuradas da bacia")
    end
  end
end
