class CreateAlarmStateHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :alarm_state_histories do |t|
      t.references :alarm, null: false, foreign_key: true
      t.string :previous_state, null: false
      t.string :new_state, null: false
      t.text :reason, null: false
      t.jsonb :datapoints, default: []
      t.datetime :evaluated_at, null: false

      t.timestamps
    end

    add_index :alarm_state_histories, [:alarm_id, :created_at], order: { created_at: :desc }
  end
end
