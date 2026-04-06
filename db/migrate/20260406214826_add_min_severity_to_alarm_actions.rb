class AddMinSeverityToAlarmActions < ActiveRecord::Migration[8.1]
  def change
    add_column :alarm_actions, :min_severity, :integer
  end
end
