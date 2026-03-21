class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :role, null: false, default: "operator"
      t.string :phone_number
      t.string :department
      t.boolean :active, default: true
      t.boolean :receives_sms_alerts, default: true
      t.jsonb :notification_preferences, default: {}
      t.timestamps
    end

    add_index :users, :email_address, unique: true
  end
end
