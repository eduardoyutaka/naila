class RemoveRiverFromAlarms < ActiveRecord::Migration[8.1]
  def change
    remove_reference :alarms, :river, foreign_key: true, index: true
  end
end
