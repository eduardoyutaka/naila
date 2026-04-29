class DropRiskEngineColumnsAndTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :risk_assessments

    remove_column :river_basins, :current_risk_level
    remove_column :river_basins, :current_risk_score
    remove_column :river_basins, :risk_factors
    remove_column :river_basins, :risk_updated_at
    remove_column :river_basins, :base_risk_level

    remove_column :neighborhoods, :current_risk_level
  end

  def down
    add_column :neighborhoods, :current_risk_level, :integer, default: 0
    add_index :neighborhoods, :current_risk_level

    add_column :river_basins, :base_risk_level, :integer, default: 0
    add_column :river_basins, :risk_updated_at, :timestamp
    add_column :river_basins, :risk_factors, :jsonb, default: {}
    add_column :river_basins, :current_risk_score, :float
    add_column :river_basins, :current_risk_level, :integer, default: 0
    add_index :river_basins, :current_risk_level

    create_table :risk_assessments do |t|
      t.references :river_basin, null: false, foreign_key: true
      t.timestamp :assessed_at, null: false
      t.integer :risk_level, null: false
      t.float :risk_score, null: false
      t.float :precipitation_score
      t.float :soil_moisture_score
      t.float :forecast_score
      t.jsonb :contributing_factors, default: {}
      t.jsonb :sensor_data_snapshot, default: {}
      t.timestamps
    end
    add_index :risk_assessments, :risk_level
    add_index :risk_assessments, [:river_basin_id, :assessed_at]
  end
end
