module Admin
  class NotificationRulesController < BaseController
    include Filterable

    skip_after_action :verify_authorized, only: :index
    after_action :verify_policy_scoped, only: :index

    before_action :set_rule, only: [ :edit, :update, :destroy ]
    before_action -> { authorize NotificationRule }, only: [ :index, :new, :create ]
    before_action -> { authorize @rule }, only: [ :edit, :update, :destroy ]

    def index
      base_scope = policy_scope(NotificationRule)
      @summary_counts = rule_summary_counts(base_scope)

      q = filter_params(:channel, :min_severity, :enabled)
      scope = base_scope
      scope = scope.for_channel(q[:channel])                 if q[:channel].present?
      scope = scope.where(min_severity: q[:min_severity])    if q[:min_severity].present?
      scope = scope.where(enabled: q[:enabled])              if q[:enabled].present?

      @rules = scope.includes(:users).order(:min_severity, :name)
    end

    def new
      @rule = NotificationRule.new(channel: "email", min_severity: 2, enabled: true)
    end

    def create
      @rule = NotificationRule.new(rule_params)

      if @rule.save
        redirect_to admin_notification_rules_path, notice: "Regra criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @rule.update(rule_params)
        redirect_to admin_notification_rules_path, notice: "Regra atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @rule.destroy!
      redirect_to admin_notification_rules_path, notice: "Regra removida."
    end

    private

    def rule_summary_counts(scope)
      {
        total:   scope.count,
        email:   scope.for_channel("email").count,
        sms:     scope.for_channel("sms").count,
        enabled: scope.enabled.count
      }
    end

    def set_rule
      @rule = NotificationRule.find(params[:id])
    end

    def rule_params
      permitted = params.require(:notification_rule).permit(
        :name, :description, :channel, :min_severity, :enabled,
        :target_admins, :target_coordinators, :target_operators,
        user_ids: []
      )
      # `collection_select` multiple submits a blank hidden value — drop it.
      permitted[:user_ids] = Array(permitted[:user_ids]).reject(&:blank?) if permitted.key?(:user_ids)
      permitted
    end
  end
end
