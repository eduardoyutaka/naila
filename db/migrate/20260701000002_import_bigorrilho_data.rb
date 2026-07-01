class ImportBigorrilhoData < ActiveRecord::Migration[8.1]
  def up
    BigorrilhoImporter.run!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
