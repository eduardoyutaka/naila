class CreateNeighborhoods < ActiveRecord::Migration[8.0]
  def change
    create_table :neighborhoods do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.references :region, foreign_key: true
      t.st_polygon :boundary, srid: 4326
      t.float :area_km2
      t.integer :population
      t.integer :current_risk_level, default: 0
      t.timestamps
    end

    add_index :neighborhoods, :boundary, using: :gist
    add_index :neighborhoods, :code, unique: true
    add_index :neighborhoods, :current_risk_level
  end
end
