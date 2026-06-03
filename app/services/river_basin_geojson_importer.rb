class RiverBasinGeojsonImporter
  GEOJSON_DIR = Rails.root.join("BD_geojson")
  SOURCE_SRID = 31982
  TARGET_SRID = 4326

  LEGACY_RENAME = {
    "Bacia do Rio Belém"             => "Rio Belém",
    "Bacia do Rio Atuba"             => "Rio Atuba",
    "Bacia do Rio Barigui"           => "Rio Barigui",
    "Bacia do Rio Passaúna"          => "Rio Passaúna",
    "Bacia do Ribeirão dos Padilhas" => "Rio Padilha",
    "Bacia do Rio Iguaçu"            => "Área Alto Iguaçu"
  }.freeze

  BASIN_NAME_BY_SOURCE = {
    "AREA DE CONTRIBUICAO DIRETA DO ALTO RIO IGUACU" => "Área Alto Iguaçu",
    "ARROIO MASCATE"          => "Arroio Mascate",
    "RIBEIRAO DA DIVISA"      => "Ribeirão da Divisa",
    "RIO ALTO BOQUEIRAO"      => "Rio Alto Boqueirão",
    "RIO ATUBA"               => "Rio Atuba",
    "RIO AVARIU"              => "Rio Avariú",
    "RIO BARIGUI"             => "Rio Barigui",
    "RIO BELEM"               => "Rio Belém",
    "RIO COTIA"               => "Rio Cotia",
    "RIO DA RESSACA"          => "Rio da Ressaca",
    "RIO DO DESPIQUE"         => "Rio do Despique",
    "RIO DO MEIO"             => "Rio do Meio",
    "RIO FAXINAL"             => "Rio Faxinal",
    "RIO GUAJUVIRA"           => "Rio Guajuvira",
    "RIO IRAI"                => "Rio Iraí",
    "RIO IRAIZINHO"           => "Rio Iraizinho",
    "RIO ISABEL ALVES"        => "Rio Isabel Alves",
    "RIO ITAQUI_CAMPO_LARGO"  => "Rio Itaqui (Campo Largo)",
    "RIO ITAQUI_SJP"          => "Rio Itaqui (SJP)",
    "RIO MAURICIO"            => "Rio Maurício",
    "RIO MIRINGUAVA"          => "Rio Miringuava",
    "RIO MIRINGUAVA-MIRIM"    => "Rio Miringuava-Mirim",
    "RIO PADILHA"             => "Rio Padilha",
    "RIO PALMITAL"            => "Rio Palmital",
    "RIO PASSAUNA"            => "Rio Passaúna",
    "RIO PEQUENO"             => "Rio Pequeno",
    "RIO PIRAQUARA"           => "Rio Piraquara",
    "RIO PIUNDUVA"            => "Rio Piunduva",
    "RIO TURVO"               => "Rio Turvo",
    "RIO VERDE"               => "Rio Verde"
  }.freeze

  REPROJECT_AND_FLATTEN = <<~SQL.squish.freeze
    ST_GeometryN(
      ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON(?), #{SOURCE_SRID}), #{TARGET_SRID}),
      1
    )
  SQL

  def self.run!
    new.run!
  end

  def run!
    ActiveRecord::Base.transaction do
      Dir.glob(GEOJSON_DIR.join("*.geojson")).sort.each { |path| import(path) }
      rename_legacy_alarms
    end
  end

  private

  def import(path)
    feature  = JSON.parse(File.read(path)).fetch("features").first
    props    = feature.fetch("properties")
    new_name = BASIN_NAME_BY_SOURCE.fetch(props.fetch("NOME_BACIA"))
    area     = props.fetch("SUB_AREA")
    geom     = feature.fetch("geometry").to_json
    legacy   = LEGACY_RENAME.invert[new_name]

    candidates = [new_name, legacy].compact
    existing_id = connection.select_value(sanitize([
      "SELECT id FROM river_basins WHERE name IN (?) LIMIT 1", candidates
    ]))

    if existing_id
      connection.execute(sanitize([
        <<~SQL.squish, new_name, area, geom, existing_id
          UPDATE river_basins
          SET name = ?, area_km2 = ?,
              geometry = #{REPROJECT_AND_FLATTEN},
              active = TRUE, updated_at = NOW()
          WHERE id = ?
        SQL
      ]))
    else
      connection.execute(sanitize([
        <<~SQL.squish, new_name, area, geom
          INSERT INTO river_basins
            (name, area_km2, geometry, active, created_at, updated_at)
          VALUES
            (?, ?, #{REPROJECT_AND_FLATTEN}, TRUE, NOW(), NOW())
        SQL
      ]))
    end
  end

  def rename_legacy_alarms
    LEGACY_RENAME.each do |legacy, new_name|
      connection.execute(sanitize([
        "UPDATE alarms SET name = ?, updated_at = NOW() WHERE name = ?",
        "Precipitação 3h — #{new_name}",
        "Precipitação 3h — #{legacy}"
      ]))
    end
  end

  def connection
    ActiveRecord::Base.connection
  end

  def sanitize(array)
    ActiveRecord::Base.sanitize_sql_array(array)
  end
end
