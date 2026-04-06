class CreateCompositeAlarmChildren < ActiveRecord::Migration[8.1]
  def change
    create_table :composite_alarm_children do |t|
      t.references :composite_alarm, null: false, foreign_key: { to_table: :alarms }
      t.references :child_alarm, null: false, foreign_key: { to_table: :alarms }

      t.timestamps
    end

    add_index :composite_alarm_children, [:composite_alarm_id, :child_alarm_id],
              unique: true, name: "idx_composite_alarm_children_uniqueness"
  end
end
