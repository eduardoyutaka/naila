class CreateAlarmActions < ActiveRecord::Migration[8.1]
  def change
    create_table :alarm_actions do |t|
      t.references :alarm, null: false, foreign_key: true
      t.string :trigger_state, null: false
      t.string :action_type, null: false
      t.jsonb :configuration, null: false, default: {}
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :alarm_actions, [:alarm_id, :trigger_state]
  end
end
