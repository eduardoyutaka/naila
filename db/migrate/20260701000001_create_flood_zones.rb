class CreateFloodZones < ActiveRecord::Migration[8.1]
  def change
    create_table :flood_zones do |t|
      t.references :river_basin, null: false, foreign_key: true
      t.integer :return_period, null: false          # years (5, 10, 25, 100, 200, 500)
      t.float :area_m2                                # flooded extent, from source properties.Area
      t.st_multi_polygon :geometry, srid: 4326        # disjoint flood patches; nullable like river_basins.geometry

      t.timestamps
    end

    add_index :flood_zones, :geometry, using: :gist
    add_index :flood_zones, [ :river_basin_id, :return_period ], unique: true
  end
end
