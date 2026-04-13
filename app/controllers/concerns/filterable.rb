module Filterable
  extend ActiveSupport::Concern

  private

  # Returns permitted filter params from the :q namespace.
  # Each controller passes its own allowlist:
  #   filter_params(:search, :state, :enabled)
  def filter_params(*keys)
    params.fetch(:q, {}).permit(*keys)
  end

  # Applies an ILIKE search across one or more columns.
  # Returns the scope unchanged if the term is blank.
  #   apply_search(scope, "chuva", :name)
  #   apply_search(scope, "rio", :name, :description)
  def apply_search(scope, term, *columns)
    return scope if term.blank?

    sanitized = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    conditions = columns.map { |col| "#{col} ILIKE :q" }.join(" OR ")
    scope.where(conditions, q: sanitized)
  end
end
