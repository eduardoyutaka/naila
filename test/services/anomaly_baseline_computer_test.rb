require "test_helper"

class AnomalyBaselineComputerTest < ActiveSupport::TestCase
  setup do
    @basin = river_basins(:bacia_belem)
    @river = rivers(:belem)
  end

  test "computes baseline from precipitation sensor readings" do
    baseline = AnomalyBaselineComputer.compute(
      metric_name: "precipitation_1h",
      river_basin: @basin,
      training_window_days: 30
    )

    assert_instance_of AnomalyBaseline, baseline
    assert_equal "precipitation_1h", baseline.metric_name
    assert_equal @basin, baseline.river_basin
    assert_equal 30, baseline.training_window_days
    assert baseline.baseline_data.is_a?(Hash)
    assert baseline.baseline_data.key?("hourly")
  end

  test "computes baseline from river level readings" do
    baseline = AnomalyBaselineComputer.compute(
      metric_name: "river_level",
      river_basin: @basin,
      river: @river,
      training_window_days: 30
    )

    assert_instance_of AnomalyBaseline, baseline
    assert_equal "river_level", baseline.metric_name
    assert_equal @river, baseline.river
  end

  test "baseline has mean and stddev per hour/day bucket" do
    baseline = AnomalyBaselineComputer.compute(
      metric_name: "precipitation_1h",
      river_basin: @basin,
      training_window_days: 30
    )

    hourly = baseline.baseline_data["hourly"]
    assert hourly.is_a?(Hash)

    # At least one bucket should have data from fixtures
    non_empty = hourly.values.flat_map(&:values).reject { |v| v["count"] == 0 }
    assert non_empty.any?, "expected at least one bucket with data"

    sample = non_empty.first
    assert sample.key?("mean")
    assert sample.key?("stddev")
    assert sample.key?("count")
  end

  test "upserts existing baseline" do
    existing = anomaly_baselines(:precipitation_belem)

    assert_no_difference "AnomalyBaseline.count" do
      AnomalyBaselineComputer.compute(
        metric_name: existing.metric_name,
        river_basin: existing.river_basin,
        training_window_days: 30
      )
    end

    existing.reload
    assert existing.computed_at > 1.minute.ago
  end

  test "creates new baseline when none exists" do
    assert_difference "AnomalyBaseline.count", 1 do
      AnomalyBaselineComputer.compute(
        metric_name: "risk_score",
        river_basin: @basin,
        training_window_days: 90
      )
    end
  end
end
