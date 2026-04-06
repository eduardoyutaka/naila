class AddCurrentSeverityToAlarms < ActiveRecord::Migration[8.1]
  def change
    add_column :alarms, :current_severity, :integer
    add_index  :alarms, :current_severity
  end
end
