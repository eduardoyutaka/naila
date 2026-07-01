require "test_helper"

class BigorrilhoImporterTest < ActiveSupport::TestCase
  # Reads geometry facts straight from PostGIS so we verify the reprojection
  # (coords must be Curitiba lon/lat in 4326, not UTM meters).
  def geom_facts(table, id)
    ActiveRecord::Base.connection.select_one(<<~SQL)
      SELECT ST_SRID(geometry) AS srid,
             GeometryType(geometry) AS gtype,
             ST_X(ST_PointOnSurface(geometry)) AS x,
             ST_Y(ST_PointOnSurface(geometry)) AS y
      FROM #{table} WHERE id = #{id.to_i}
    SQL
  end

  test "imports the Córrego Bigorrilho watershed as a 4326 polygon in Curitiba" do
    BigorrilhoImporter.run!

    basin = RiverBasin.find_by(name: "Córrego Bigorrilho")
    assert basin, "expected the Córrego Bigorrilho basin to be created"

    f = geom_facts("river_basins", basin.id)
    assert_equal 4326, f["srid"].to_i
    assert_equal "POLYGON", f["gtype"]
    assert_in_delta(-49.3, f["x"].to_f, 0.4, "longitude should be Curitiba lon/lat, not UTM meters")
    assert_in_delta(-25.44, f["y"].to_f, 0.4)
    assert basin.area_km2.to_f.positive?, "area_km2 should be computed from the geometry"
  end

  test "imports the 6 return-period flood zones as 4326 multipolygons" do
    BigorrilhoImporter.run!

    zones = RiverBasin.find_by(name: "Córrego Bigorrilho").flood_zones.order(:return_period)
    assert_equal [ 5, 10, 25, 100, 200, 500 ], zones.pluck(:return_period)

    f = geom_facts("flood_zones", zones.first.id)
    assert_equal 4326, f["srid"].to_i
    assert_equal "MULTIPOLYGON", f["gtype"], "flood manchas are multi-part and must not be flattened"
    assert_in_delta(-49.3, f["x"].to_f, 0.4)
    assert_in_delta(-25.44, f["y"].to_f, 0.4)
  end

  test "is idempotent — re-running keeps a single basin and 6 zones" do
    BigorrilhoImporter.run!
    BigorrilhoImporter.run!

    assert_equal 1, RiverBasin.where(name: "Córrego Bigorrilho").count
    assert_equal 6, RiverBasin.find_by(name: "Córrego Bigorrilho").flood_zones.count
  end
end
