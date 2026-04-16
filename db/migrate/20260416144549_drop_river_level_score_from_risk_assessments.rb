class DropRiverLevelScoreFromRiskAssessments < ActiveRecord::Migration[8.1]
  def change
    remove_column :risk_assessments, :river_level_score, :float
  end
end
