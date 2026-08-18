class AddEpisodePeakSeverityToAlarms < ActiveRecord::Migration[8.1]
  def change
    add_column :alarms, :episode_peak_severity, :integer
  end
end
