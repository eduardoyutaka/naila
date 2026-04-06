require "test_helper"

class AnomalyBaselineTest < ActiveSupport::TestCase
  # ── Validations ──

  test "valid with all required fields" do
    baseline = AnomalyBaseline.new(
      metric_name: "soil_moisture",
      computed_at: Time.current,
      training_window_days: 90
    )
    assert baseline.valid?
  end

  test "invalid without metric_name" do
    baseline = anomaly_baselines(:precipitation_belem)
    baseline.metric_name = nil
    assert_not baseline.valid?
  end

  test "invalid without computed_at" do
    baseline = anomaly_baselines(:precipitation_belem)
    baseline.computed_at = nil
    assert_not baseline.valid?
  end

  test "invalid without training_window_days" do
    baseline = anomaly_baselines(:precipitation_belem)
    baseline.training_window_days = nil
    assert_not baseline.valid?
  end

  test "training_window_days must be positive" do
    baseline = anomaly_baselines(:precipitation_belem)
    baseline.training_window_days = 0
    assert_not baseline.valid?
  end

  test "unique constraint on metric_name, river_basin_id, river_id" do
    existing = anomaly_baselines(:precipitation_belem)
    duplicate = AnomalyBaseline.new(
      metric_name: existing.metric_name,
      river_basin: existing.river_basin,
      river: existing.river,
      computed_at: Time.current,
      training_window_days: 30
    )
    assert_not duplicate.valid?
  end

  # ── Associations ──

  test "belongs to river basin optionally" do
    assert_equal river_basins(:bacia_belem), anomaly_baselines(:precipitation_belem).river_basin
  end

  test "belongs to river optionally" do
    assert_equal rivers(:belem), anomaly_baselines(:river_level_belem).river
    assert_nil anomaly_baselines(:precipitation_belem).river
  end

  test "has many alarms" do
    baseline = anomaly_baselines(:precipitation_belem)
    assert_includes baseline.alarms, alarms(:anomaly_precip_belem)
  end
end
