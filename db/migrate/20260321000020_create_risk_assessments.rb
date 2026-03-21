class CreateRiskAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :risk_assessments do |t|
      t.references :risk_zone, null: false, foreign_key: true
      t.datetime :assessed_at, null: false
      t.integer :risk_level, null: false
      t.float :risk_score, null: false
      t.float :precipitation_score
      t.float :river_level_score
      t.float :soil_moisture_score
      t.float :forecast_score
      t.jsonb :contributing_factors, default: {}
      t.jsonb :sensor_data_snapshot, default: {}
      t.timestamps
    end

    add_index :risk_assessments, [:risk_zone_id, :assessed_at]
    add_index :risk_assessments, :risk_level
  end
end
