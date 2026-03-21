class CreateEvacuationRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :evacuation_routes do |t|
      t.string :name, null: false
      t.text :description
      t.st_line_string :path, srid: 4326
      t.references :risk_zone, foreign_key: true
      t.string :destination_name
      t.st_point :destination_point, srid: 4326
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :evacuation_routes, :path, using: :gist
  end
end
