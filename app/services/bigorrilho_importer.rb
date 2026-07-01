class BigorrilhoImporter
  DIR = Rails.root.join("db/geojson/bigorrilho")
  BASIN_NAME = "Córrego Bigorrilho".freeze

  # Watershed outline is EPSG:4674 (SIRGAS 2000, lon/lat). Flatten its single-part
  # MultiPolygon to a Polygon so it fits river_basins.geometry (Polygon,4326).
  WATERSHED_GEOM = "ST_GeometryN(ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON(?), 4674), 4326), 1)".freeze
  # Flood manchas are EPSG:31982 (UTM 22S, meters). Keep the (multi-part) MultiPolygon.
  FLOOD_GEOM = "ST_Multi(ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON(?), 31982), 4326))".freeze

  def self.run!
    new.run!
  end

  def run!
    ActiveRecord::Base.transaction do
      basin_id = import_watershed
      import_flood_zones(basin_id)
    end
  end

  private

  def import_watershed
    geom = geometry_json(DIR.join("watershed.geojson"))

    id = connection.select_value(sanitize([ "SELECT id FROM river_basins WHERE name = ? LIMIT 1", BASIN_NAME ]))

    if id
      connection.execute(sanitize([
        "UPDATE river_basins SET geometry = #{WATERSHED_GEOM}, active = TRUE, updated_at = NOW() WHERE id = ?",
        geom, id
      ]))
    else
      id = connection.select_value(sanitize([
        "INSERT INTO river_basins (name, geometry, active, created_at, updated_at) " \
        "VALUES (?, #{WATERSHED_GEOM}, TRUE, NOW(), NOW()) RETURNING id",
        BASIN_NAME, geom
      ]))
    end

    connection.execute(sanitize([
      "UPDATE river_basins SET area_km2 = ST_Area(geometry::geography) / 1000000.0 WHERE id = ?", id
    ]))
    id
  end

  def import_flood_zones(basin_id)
    Dir.glob(DIR.join("flood_zones", "*.geojson")).sort.each do |path|
      return_period = File.basename(path, ".geojson").to_i
      feature = JSON.parse(File.read(path)).fetch("features").first
      area    = feature.fetch("properties")["Area"]
      geom    = feature.fetch("geometry").to_json

      id = connection.select_value(sanitize([
        "SELECT id FROM flood_zones WHERE river_basin_id = ? AND return_period = ? LIMIT 1", basin_id, return_period
      ]))

      if id
        connection.execute(sanitize([
          "UPDATE flood_zones SET area_m2 = ?, geometry = #{FLOOD_GEOM}, updated_at = NOW() WHERE id = ?",
          area, geom, id
        ]))
      else
        connection.execute(sanitize([
          "INSERT INTO flood_zones (river_basin_id, return_period, area_m2, geometry, created_at, updated_at) " \
          "VALUES (?, ?, ?, #{FLOOD_GEOM}, NOW(), NOW())",
          basin_id, return_period, area, geom
        ]))
      end
    end
  end

  def geometry_json(path)
    JSON.parse(File.read(path)).fetch("features").first.fetch("geometry").to_json
  end

  def connection
    ActiveRecord::Base.connection
  end

  def sanitize(array)
    ActiveRecord::Base.sanitize_sql_array(array)
  end
end
