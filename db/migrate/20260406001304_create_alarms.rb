class CreateAlarms < ActiveRecord::Migration[8.1]
  def change
    create_table :alarms do |t|
      t.string :name, null: false
      t.text :description
      t.string :alarm_type, null: false
      t.string :state, null: false, default: "insufficient_data"
      t.datetime :state_changed_at
      t.text :state_reason
      t.integer :severity, null: false
      t.boolean :enabled, default: true, null: false

      # Scope
      t.references :river_basin, foreign_key: true
      t.references :river, foreign_key: true

      # Metric alarm fields
      t.string :metric_name
      t.string :statistic
      t.integer :period_seconds
      t.integer :evaluation_periods
      t.integer :datapoints_to_alarm
      t.string :comparison_operator
      t.float :threshold_value
      t.string :unit
      t.string :missing_data_treatment, default: "missing"

      # Anomaly detection fields
      t.float :anomaly_band_width
      t.references :anomaly_baseline, foreign_key: true

      # Composite alarm fields
      t.text :composite_rule
      t.boolean :suppress_child_actions, default: false, null: false

      # Evaluation state
      t.datetime :last_evaluated_at
      t.jsonb :last_datapoints, default: []

      t.timestamps
    end

    add_index :alarms, :state
    add_index :alarms, :alarm_type
    add_index :alarms, [:river_basin_id, :state]
    add_index :alarms, [:enabled, :alarm_type]
  end
end
