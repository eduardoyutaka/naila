class ImportRiverBasinsFromGeojson < ActiveRecord::Migration[8.0]
  def up
    RiverBasinGeojsonImporter.run!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
