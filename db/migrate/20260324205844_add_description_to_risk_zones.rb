class AddDescriptionToRiskZones < ActiveRecord::Migration[8.1]
  def change
    add_column :risk_zones, :description, :text
  end
end
