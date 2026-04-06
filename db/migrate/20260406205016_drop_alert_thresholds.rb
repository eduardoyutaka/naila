class DropAlertThresholds < ActiveRecord::Migration[8.1]
  def change
    remove_reference :alerts, :alert_threshold, foreign_key: true, null: true
    drop_table :alert_thresholds
  end
end
