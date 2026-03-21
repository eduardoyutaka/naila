class CreateDrainageBasins < ActiveRecord::Migration[8.0]
  def change
    create_table :drainage_basins do |t|
      t.string :name, null: false
      t.st_polygon :boundary, srid: 4326
      t.float :area_km2
      t.timestamps
    end

    add_index :drainage_basins, :boundary, using: :gist
  end
end
