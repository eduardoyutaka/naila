class CreateAnomalyBaselines < ActiveRecord::Migration[8.1]
  def change
    create_table :anomaly_baselines do |t|
      t.string :metric_name, null: false
      t.references :river_basin, foreign_key: true
      t.references :river, foreign_key: true
      t.jsonb :baseline_data, null: false, default: {}
      t.datetime :computed_at, null: false
      t.integer :training_window_days, null: false

      t.timestamps
    end

    add_index :anomaly_baselines, [:metric_name, :river_basin_id, :river_id],
              unique: true, name: "idx_anomaly_baselines_uniqueness"
  end
end
