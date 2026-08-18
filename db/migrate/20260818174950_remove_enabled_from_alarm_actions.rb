class RemoveEnabledFromAlarmActions < ActiveRecord::Migration[8.1]
  def up
    # A disabled action represented "not really configured" under the old model —
    # dropping the column without removing these first would silently resurrect
    # them as active.
    execute "DELETE FROM alarm_actions WHERE enabled = false"
    remove_column :alarm_actions, :enabled
  end

  def down
    add_column :alarm_actions, :enabled, :boolean, default: true, null: false
  end
end
