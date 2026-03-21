class CreateRiskZones < ActiveRecord::Migration[8.0]
  def change
    create_table :risk_zones do |t|
      t.string :name, null: false
      t.string :zone_type, null: false
      t.st_polygon :geometry, srid: 4326
      t.references :drainage_basin, foreign_key: true
      t.references :neighborhood, foreign_key: true
      t.integer :base_risk_level, default: 0
      t.integer :current_risk_level, default: 0
      t.float :current_risk_score
      t.jsonb :risk_factors, default: {}
      t.datetime :risk_updated_at
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :risk_zones, :geometry, using: :gist
    add_index :risk_zones, :current_risk_level
    add_index :risk_zones, :zone_type
  end
end
