class RemoveCompositeAndAnomalyAlarmSupport < ActiveRecord::Migration[8.1]
  def up
    # Remove composite alarms and all dependents
    execute <<~SQL
      DELETE FROM alarm_actions WHERE alarm_id IN (SELECT id FROM alarms WHERE alarm_type IN ('composite', 'anomaly_detection'));
      DELETE FROM alarm_state_histories WHERE alarm_id IN (SELECT id FROM alarms WHERE alarm_type IN ('composite', 'anomaly_detection'));
      DELETE FROM composite_alarm_children;
      DELETE FROM alarms WHERE alarm_type IN ('composite', 'anomaly_detection');
    SQL
    drop_table :composite_alarm_children
    remove_column :alarms, :anomaly_baseline_id
    drop_table :anomaly_baselines

    # Remove remaining composite/anomaly-only columns from alarms
    remove_column :alarms, :anomaly_band_width
    remove_column :alarms, :composite_rule
    remove_column :alarms, :suppress_child_actions
  end

  def down
    add_column :alarms, :suppress_child_actions, :boolean, default: false, null: false
    add_column :alarms, :composite_rule,         :text
    add_column :alarms, :anomaly_baseline_id,    :bigint
    add_column :alarms, :anomaly_band_width,     :float

    create_table :anomaly_baselines do |t|
      t.references :river_basin, foreign_key: { on_delete: :cascade }
      t.references :river,       foreign_key: { on_delete: :cascade }
      t.float      :mean
      t.float      :std_dev
      t.integer    :sample_count
      t.datetime   :computed_at
      t.timestamps
    end

    create_table :composite_alarm_children do |t|
      t.references :composite_alarm, null: false, foreign_key: { to_table: :alarms, on_delete: :cascade }
      t.references :child_alarm,     null: false, foreign_key: { to_table: :alarms, on_delete: :cascade }
      t.timestamps
    end
    add_index :composite_alarm_children, [ :composite_alarm_id, :child_alarm_id ], unique: true,
              name: "index_composite_alarm_children_on_both_alarm_ids"
  end
end
