class DataSource < ApplicationRecord
  validates :name, :source_type, presence: true
  validates :source_type, inclusion: { in: %w[api mqtt webhook] }

  scope :active, -> { where(status: "active") }
  scope :degraded, -> { where(status: "degraded") }
  scope :offline, -> { where(status: "offline") }

  def record_success!
    update!(
      status: "active",
      last_successful_fetch_at: Time.current,
      consecutive_failures: 0
    )
  end

  def record_failure!
    new_failures = consecutive_failures + 1
    new_status = new_failures >= 3 ? "offline" : "degraded"

    update!(
      status: new_status,
      last_failed_fetch_at: Time.current,
      consecutive_failures: new_failures
    )
  end
end
