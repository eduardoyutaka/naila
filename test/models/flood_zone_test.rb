require "test_helper"

class FloodZoneTest < ActiveSupport::TestCase
  setup { @basin = river_basins(:bacia_belem) }

  test "valid with a known return period and a basin" do
    assert FloodZone.new(river_basin: @basin, return_period: 100).valid?
  end

  test "requires a return_period" do
    fz = FloodZone.new(river_basin: @basin)
    assert fz.invalid?
    assert fz.errors[:return_period].any?
  end

  test "rejects a return_period outside the known set" do
    fz = FloodZone.new(river_basin: @basin, return_period: 7)
    assert fz.invalid?
    assert fz.errors[:return_period].any?
  end

  test "requires a river_basin" do
    fz = FloodZone.new(return_period: 100)
    assert fz.invalid?
    assert fz.errors[:river_basin].any?
  end

  test "return_period is unique per river_basin" do
    FloodZone.create!(river_basin: @basin, return_period: 100)
    dup = FloodZone.new(river_basin: @basin, return_period: 100)
    assert dup.invalid?
    assert dup.errors[:return_period].any?
  end
end
