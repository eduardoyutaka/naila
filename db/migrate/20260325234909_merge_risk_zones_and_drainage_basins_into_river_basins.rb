class MergeRiskZonesAndDrainageBasinsIntoRiverBasins < ActiveRecord::Migration[8.1]
  def change
    # Phase 1: Rename risk_zones → river_basins
    rename_table :risk_zones, :river_basins

    # Phase 2: Add area_km2 from drainage_basins
    add_column :river_basins, :area_km2, :float

    # Phase 3: Remove columns that don't apply to river basins
    remove_column :river_basins, :zone_type, :string
    remove_reference :river_basins, :drainage_basin, foreign_key: true, index: true
    remove_reference :river_basins, :neighborhood, foreign_key: true, index: true

    # Phase 4: Rename risk_zone_id → river_basin_id in dependent tables
    # (foreign keys auto-update when renaming the table in PostgreSQL,
    #  but we still need to rename the columns)
    remove_foreign_key :risk_assessments, :river_basins, column: :risk_zone_id
    rename_column :risk_assessments, :risk_zone_id, :river_basin_id
    add_foreign_key :risk_assessments, :river_basins

    remove_foreign_key :alerts, :river_basins, column: :risk_zone_id
    rename_column :alerts, :risk_zone_id, :river_basin_id
    add_foreign_key :alerts, :river_basins

    remove_foreign_key :alert_thresholds, :river_basins, column: :risk_zone_id
    rename_column :alert_thresholds, :risk_zone_id, :river_basin_id
    add_foreign_key :alert_thresholds, :river_basins

    remove_foreign_key :evacuation_routes, :river_basins, column: :risk_zone_id
    rename_column :evacuation_routes, :risk_zone_id, :river_basin_id
    add_foreign_key :evacuation_routes, :river_basins

    # Phase 5: Move rivers/sensors FK from drainage_basins → river_basins
    remove_foreign_key :rivers, :drainage_basins
    rename_column :rivers, :drainage_basin_id, :river_basin_id
    add_foreign_key :rivers, :river_basins

    remove_foreign_key :sensor_stations, :drainage_basins
    rename_column :sensor_stations, :drainage_basin_id, :river_basin_id
    add_foreign_key :sensor_stations, :river_basins

    # Phase 6: Drop drainage_basins table
    drop_table :drainage_basins do |t|
      t.string :name, null: false
      t.st_polygon :boundary, srid: 4326
      t.float :area_km2
      t.timestamps
    end
  end
end
