class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :created_alerts, class_name: "Alert", foreign_key: :created_by_id, dependent: :nullify, inverse_of: :created_by
  has_many :resolved_alerts, class_name: "Alert", foreign_key: :resolved_by_id, dependent: :nullify, inverse_of: :resolved_by

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[operator coordinator admin] }

  scope :active, -> { where(active: true) }
  scope :sms_recipients, -> { active.where(receives_sms_alerts: true).where.not(phone_number: nil) }

  def admin?
    role == "admin"
  end

  def coordinator?
    role == "coordinator"
  end

  def operator?
    role == "operator"
  end

  def can_manage_users?
    admin?
  end

  def can_manage_alerts?
    admin? || coordinator?
  end

  # Override the default 15-minute expiry from has_secure_password
  generates_token_for :password_reset, expires_in: 2.hours do
    password_salt&.last(10)
  end
end
