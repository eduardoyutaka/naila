class AddSeverityToAlarmStateHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :alarm_state_histories, :previous_severity, :integer
    add_column :alarm_state_histories, :new_severity, :integer
  end
end
