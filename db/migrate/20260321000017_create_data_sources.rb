class CreateDataSources < ActiveRecord::Migration[8.0]
  def change
    create_table :data_sources do |t|
      t.string :name, null: false
      t.string :source_type, null: false
      t.string :base_url
      t.string :status, default: "active"
      t.datetime :last_successful_fetch_at
      t.datetime :last_failed_fetch_at
      t.integer :consecutive_failures, default: 0
      t.integer :fetch_interval_seconds, default: 600
      t.jsonb :configuration, default: {}
      t.timestamps
    end
  end
end
