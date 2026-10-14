class AddAcknowledgmentToAlarms < ActiveRecord::Migration[8.1]
  def change
    add_column :alarms, :acknowledged_at, :datetime
    add_reference :alarms, :acknowledged_by, foreign_key: { to_table: :users }, null: true
  end
end
