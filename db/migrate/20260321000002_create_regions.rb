class CreateRegions < ActiveRecord::Migration[8.0]
  def change
    create_table :regions do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.st_polygon :boundary, srid: 4326
      t.timestamps
    end

    add_index :regions, :boundary, using: :gist
    add_index :regions, :code, unique: true
  end
end
