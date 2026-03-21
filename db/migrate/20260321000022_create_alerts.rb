class CreateAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.text :instructions
      t.integer :severity, null: false
      t.string :alert_type, null: false
      t.string :status, default: "active"
      t.references :risk_zone, foreign_key: true, null: true
      t.references :neighborhood, foreign_key: true, null: true
      t.references :river, foreign_key: true, null: true
      t.references :alert_threshold, foreign_key: true, null: true
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.references :resolved_by, foreign_key: { to_table: :users }, null: true
      t.st_polygon :affected_area, srid: 4326
      t.datetime :activated_at
      t.datetime :acknowledged_at
      t.datetime :resolved_at
      t.datetime :expires_at
      t.jsonb :trigger_data, default: {}
      t.timestamps
    end

    add_index :alerts, :affected_area, using: :gist
    add_index :alerts, :severity
    add_index :alerts, :status
    add_index :alerts, [:status, :severity]
  end
end
