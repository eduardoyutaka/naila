class CreateRivers < ActiveRecord::Migration[8.0]
  def change
    create_table :rivers do |t|
      t.string :name, null: false
      t.st_line_string :course, srid: 4326
      t.references :drainage_basin, foreign_key: true
      t.float :length_km
      t.float :normal_level_m
      t.float :alert_level_m
      t.float :flood_level_m
      t.float :overflow_level_m
      t.timestamps
    end

    add_index :rivers, :course, using: :gist
  end
end
