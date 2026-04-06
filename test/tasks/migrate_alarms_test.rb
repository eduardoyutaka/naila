require "test_helper"
require "rake"

class MigrateAlarmsTaskTest < ActiveSupport::TestCase
  setup do
    # Load the rake task
    Naila::Application.load_tasks unless Rake::Task.task_defined?("alarms:migrate_thresholds")
  end

  test "migrates alert thresholds to alarms" do
    capture_io { Rake::Task["alarms:migrate_thresholds"].invoke }

    param_to_metric = { "precipitation" => "precipitation_3h", "precipitation_1h" => "precipitation_1h",
                        "precipitation_3h" => "precipitation_3h", "river_level" => "river_level" }

    AlertThreshold.find_each do |threshold|
      metric_name = param_to_metric[threshold.parameter]
      next unless metric_name

      assert Alarm.exists?(alarm_type: "metric", metric_name: metric_name,
                           river_basin: threshold.river_basin, river: threshold.river,
                           severity: threshold.severity),
             "Expected alarm for #{threshold.parameter} sev #{threshold.severity}"
    end
  ensure
    Rake::Task["alarms:migrate_thresholds"].reenable
  end

  test "creates alarm actions for each migrated alarm" do
    capture_io { Rake::Task["alarms:migrate_thresholds"].invoke }

    # Each migrated alarm should have at least an alarm-state action and an ok-state action
    Alarm.where(alarm_type: "metric").where("name LIKE ?", "%sev%").find_each do |alarm|
      assert alarm.alarm_actions.for_state("alarm").exists?,
             "Alarm '#{alarm.name}' should have an alarm-state action"
      assert alarm.alarm_actions.for_state("ok").exists?,
             "Alarm '#{alarm.name}' should have an ok-state action"
    end
  ensure
    Rake::Task["alarms:migrate_thresholds"].reenable
  end

  test "maps comparison operators correctly" do
    capture_io { Rake::Task["alarms:migrate_thresholds"].invoke }

    # precipitation_high fixture has comparison: gte
    alarm = Alarm.find_by(alarm_type: "metric", metric_name: "precipitation_3h", severity: 3)
    assert_not_nil alarm
    assert_equal "GreaterThanOrEqualToThreshold", alarm.comparison_operator
  ensure
    Rake::Task["alarms:migrate_thresholds"].reenable
  end

  test "is idempotent" do
    capture_io { Rake::Task["alarms:migrate_thresholds"].invoke }
    Rake::Task["alarms:migrate_thresholds"].reenable

    assert_no_difference "Alarm.count" do
      capture_io { Rake::Task["alarms:migrate_thresholds"].invoke }
    end
  ensure
    Rake::Task["alarms:migrate_thresholds"].reenable
  end
end
