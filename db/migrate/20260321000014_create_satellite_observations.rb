class CreateSatelliteObservations < ActiveRecord::Migration[8.0]
  def change
    create_table :satellite_observations do |t|
      t.string :source, null: false
      t.st_polygon :coverage_area, srid: 4326
      t.datetime :captured_at, null: false
      t.string :observation_type, null: false
      t.float :value
      t.string :unit
      t.string :image_url
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :satellite_observations, :coverage_area, using: :gist
    add_index :satellite_observations, [:source, :captured_at]
  end
end
