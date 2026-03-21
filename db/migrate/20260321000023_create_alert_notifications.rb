class CreateAlertNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :alert_notifications do |t|
      t.references :alert, null: false, foreign_key: true
      t.string :channel, null: false
      t.string :recipient
      t.string :status, default: "pending"
      t.datetime :sent_at
      t.datetime :delivered_at
      t.text :failure_reason
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :alert_notifications, [:alert_id, :channel]
    add_index :alert_notifications, :status
  end
end
