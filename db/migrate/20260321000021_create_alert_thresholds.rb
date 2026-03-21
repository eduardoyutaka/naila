class CreateAlertThresholds < ActiveRecord::Migration[8.0]
  def change
    create_table :alert_thresholds do |t|
      t.string :parameter, null: false
      t.string :threshold_type, null: false
      t.integer :severity, null: false
      t.float :value, null: false
      t.string :unit, null: false
      t.string :comparison, null: false
      t.references :risk_zone, foreign_key: true, null: true
      t.references :river, foreign_key: true, null: true
      t.boolean :active, default: true
      t.integer :cooldown_minutes, default: 60
      t.timestamps
    end
  end
end
