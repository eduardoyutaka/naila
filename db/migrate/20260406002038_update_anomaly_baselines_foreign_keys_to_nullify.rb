class UpdateAnomalyBaselinesForeignKeysToNullify < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :anomaly_baselines, :river_basins
    add_foreign_key :anomaly_baselines, :river_basins, on_delete: :nullify

    remove_foreign_key :anomaly_baselines, :rivers
    add_foreign_key :anomaly_baselines, :rivers, on_delete: :nullify
  end
end
