class RemoveMissingDataTreatmentFromAlarms < ActiveRecord::Migration[8.1]
  def change
    remove_column :alarms, :missing_data_treatment, :string, default: "missing"
  end
end
