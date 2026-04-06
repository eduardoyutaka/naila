class CreateAlarmThresholds < ActiveRecord::Migration[8.1]
  def change
    create_table :alarm_thresholds do |t|
      t.references :alarm, null: false, foreign_key: { on_delete: :cascade }
      t.integer    :severity,            null: false
      t.string     :comparison_operator, null: false
      t.float      :threshold_value,     null: false
      t.string     :unit

      t.timestamps
    end

    add_index :alarm_thresholds, [ :alarm_id, :severity ], unique: true
  end
end
