class CreateEscalationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :escalation_rules do |t|
      t.integer :from_severity, null: false
      t.integer :to_severity, null: false
      t.integer :escalation_after_minutes, null: false
      t.boolean :notify_supervisor, default: false
      t.string :supervisor_contact
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
