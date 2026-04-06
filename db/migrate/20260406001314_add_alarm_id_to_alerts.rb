class AddAlarmIdToAlerts < ActiveRecord::Migration[8.1]
  def change
    add_reference :alerts, :alarm, foreign_key: true
    add_column :alerts, :alarm_state, :string
  end
end
