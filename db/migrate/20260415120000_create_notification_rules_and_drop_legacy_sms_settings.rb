class CreateNotificationRulesAndDropLegacySmsSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_rules do |t|
      t.string  :name, null: false
      t.text    :description
      t.string  :channel, null: false
      t.integer :min_severity, null: false
      t.boolean :target_admins, null: false, default: false
      t.boolean :target_coordinators, null: false, default: false
      t.boolean :target_operators, null: false, default: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :notification_rules, [ :enabled, :channel, :min_severity ],
              name: "index_notification_rules_for_lookup"

    create_table :notification_rule_users do |t|
      t.references :notification_rule, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :notification_rule_users, [ :notification_rule_id, :user_id ],
              unique: true, name: "index_notification_rule_users_uniqueness"

    remove_column :users, :receives_sms_alerts, :boolean, default: true
  end
end
