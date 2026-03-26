class CreateSensors < ActiveRecord::Migration[8.1]
  def change
    create_table :sensors do |t|
      t.references :sensor_station, null: false, foreign_key: true
      t.string :sensor_type, null: false
      t.string :external_id, null: false
      t.string :unit, limit: 20
      t.string :reading_type, limit: 30
      t.string :status, default: "active"
      t.datetime :last_reading_at
      t.float :last_reading_value
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :sensors, :external_id, unique: true
    add_index :sensors, :sensor_type
    add_index :sensors, :status
  end
end
