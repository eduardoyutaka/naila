class DropAlertsAndAlertNotifications < ActiveRecord::Migration[8.1]
  def change
    drop_table :alert_notifications
    drop_table :alerts
  end
end
