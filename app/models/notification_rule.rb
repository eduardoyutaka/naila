class NotificationRule < ApplicationRecord
  CHANNELS = %w[email sms].freeze
  SEVERITIES = (1..4).freeze
  ROLE_FIELDS = %i[target_admins target_coordinators target_operators].freeze

  has_many :notification_rule_users, dependent: :destroy
  has_many :users, through: :notification_rule_users

  validates :name, presence: true, length: { maximum: 120 }
  validates :channel, presence: true, inclusion: { in: CHANNELS }
  validates :min_severity, presence: true, inclusion: { in: SEVERITIES.to_a }
  validate  :must_target_at_least_one_recipient

  accepts_nested_attributes_for :notification_rule_users, allow_destroy: true

  scope :enabled,               -> { where(enabled: true) }
  scope :for_channel,           ->(c)   { where(channel: c) }
  scope :triggered_by_severity, ->(sev) { where("min_severity <= ?", sev) }

  # Returns an ActiveRecord::Relation of active Users, deduped across role
  # targeting and explicit user list. For SMS, filters out users without phone.
  def resolved_recipients
    roles = []
    roles << "admin"       if target_admins
    roles << "coordinator" if target_coordinators
    roles << "operator"    if target_operators

    role_ids = roles.any? ? User.active.where(role: roles).pluck(:id) : []
    user_ids = users.active.pluck(:id)
    scope = User.where(id: (role_ids + user_ids).uniq)
    channel == "sms" ? scope.where.not(phone_number: [ nil, "" ]) : scope
  end

  def targeted_role_labels
    labels = []
    labels << "Administradores" if target_admins
    labels << "Coordenadores"   if target_coordinators
    labels << "Operadores"      if target_operators
    labels
  end

  private

  def must_target_at_least_one_recipient
    any_role = ROLE_FIELDS.any? { |f| public_send(f) }
    any_user = notification_rule_users.reject(&:marked_for_destruction?).any?
    errors.add(:base, "selecione ao menos um cargo ou usuário específico") unless any_role || any_user
  end
end
