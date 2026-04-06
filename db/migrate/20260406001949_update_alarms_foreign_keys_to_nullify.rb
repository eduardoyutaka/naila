class UpdateAlarmsForeignKeysToNullify < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :alarms, :river_basins
    add_foreign_key :alarms, :river_basins, on_delete: :nullify

    remove_foreign_key :alarms, :rivers
    add_foreign_key :alarms, :rivers, on_delete: :nullify

    remove_foreign_key :alarms, :anomaly_baselines
    add_foreign_key :alarms, :anomaly_baselines, on_delete: :nullify
  end
end
