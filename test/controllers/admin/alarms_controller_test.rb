require "test_helper"

class Admin::AlarmsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Authentication ──

  test "index requires authentication" do
    reset!
    get admin_alarms_path
    assert_redirected_to login_path
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_alarms_path
    assert_response :success
  end

  test "index displays alarm names" do
    get admin_alarms_path
    assert_select "td", text: /Precipitação 3h Bacia Belém/
  end

  test "index shows summary cards" do
    get admin_alarms_path
    assert_select "[data-testid='summary-total']"
    assert_select "[data-testid='summary-enabled']"
    assert_select "[data-testid='summary-alarm']"
  end

  test "index shows state badges" do
    get admin_alarms_path
    assert_select "span", text: "OK"
    assert_select "span", text: "Alarme"
  end

  test "index shows the Vigilância baseline in the severity column for non-firing alarms" do
    # precip_3h_belem is state ok with no current_severity → its Severidade cell reads Vigilância.
    get admin_alarms_path
    assert_select "span", text: "Vigilância"
  end

  test "index shows empty state when no alarms exist" do
    Alarm.destroy_all
    get admin_alarms_path
    assert_select "div", text: /Nenhum alarme encontrado/
  end

  # ── Filters ──

  test "index filters by state" do
    get admin_alarms_path(q: { state: "alarm" })
    assert_response :success
    assert_select "td", text: /Alerta de Enchente Belém/
    assert_select "td", text: /Precipitação 3h Bacia Belém/, count: 0
  end

  test "index filters by enabled" do
    get admin_alarms_path(q: { enabled: "false" })
    assert_response :success
    assert_select "td", text: /Alarme Desativado/
    assert_select "td", text: /Precipitação 3h Bacia Belém/, count: 0
  end

  test "index filters by search" do
    get admin_alarms_path(q: { search: "Enchente" })
    assert_response :success
    assert_select "td", text: /Alerta de Enchente Belém/
    assert_select "td", text: /Precipitação 3h Bacia Belém/, count: 0
  end

  test "index shows clear filters link when filters return no results" do
    get admin_alarms_path(q: { search: "nonexistent" })
    assert_response :success
    assert_select "a", text: /Limpar filtros/
  end

  # ── Show ──

  test "show renders successfully" do
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_response :success
  end

  test "show displays alarm name and state" do
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_select "h1", text: /Precipitação 3h Bacia Belém/
    assert_select "[data-testid='alarm-state']", text: "OK"
  end

  test "show displays a Vigilância severity badge for a calm (ok) alarm" do
    # Previously current_severity was nil for "ok" alarms, so the header badge was blank.
    # It's now explicitly 0, so the badge must render "Vigilância" instead of disappearing.
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_select ".mb-2.flex.flex-wrap.items-center.gap-2" do
      assert_select "span", text: "Vigilância"
    end
  end

  test "show displays configuration section" do
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_select "[data-testid='alarm-config']"
  end

  test "show displays actions section" do
    get admin_alarm_path(alarms(:precip_3h_belem))
    assert_select "[data-testid='alarm-actions']"
  end

  test "show renders the metric history chart container with readings and thresholds" do
    get admin_alarm_path(alarms(:flood_alert_belem))
    assert_select "[data-testid='alarm-history']" do
      assert_select "[data-controller~='admin--reading-chart']"
      assert_select "[data-admin--reading-chart-readings-value]" do |elements|
        readings = JSON.parse(elements.first["data-admin--reading-chart-readings-value"])
        assert_kind_of Array, readings
        assert_operator readings.length, :>, 0, "expected at least one period in chart series"
      end
      assert_select "[data-admin--reading-chart-thresholds-value]" do |elements|
        thresholds = JSON.parse(elements.first["data-admin--reading-chart-thresholds-value"])
        assert_equal 2, thresholds.length, "fixture has two thresholds (sev 2 and 3)"
        assert_includes thresholds.map { |t| t["severity"] }, 3
      end
    end
  end

  test "show spans a 48h chart window for an hourly alarm, not just its evaluation window" do
    # period_seconds: 3600 previously gave (evaluation_periods * 4).clamp(12, 48) == 12
    # periods (12h) — too narrow to survive a realistic multi-day outage. Uses an isolated
    # basin with data older than 48h so the real-data bounds don't clamp the window down
    # (flood_alert_belem's own fixture readings only span the last 12h).
    suffix = SecureRandom.hex(4)
    basin = RiverBasin.create!(name: "Window Test Basin #{suffix}", active: true)
    station = MonitoringStation.create!(
      external_id: "WINDOW-TEST-#{suffix}", name: "Window Test Station #{suffix}",
      data_source: "TEST", status: :active, river_basin: basin
    )
    sensor = Sensor.create!(
      monitoring_station: station, sensor_type: :pluviometer, external_id: "WINDOW-TEST-PLUV-#{suffix}",
      unit: "mm", reading_type: "precipitation", status: :active
    )
    # One reading older than 48h keeps the real-data bounds wide enough that the 48h
    # default window isn't clamped down (see flood_alert_belem, whose own fixture
    # readings only span 12h and would shrink the window if reused for this test).
    # One reading inside the window ensures the chart branch renders (not the empty state).
    SensorReading.create!(sensor: sensor, value: 5.0, unit: "mm", reading_type: "precipitation", recorded_at: 5.days.ago)
    SensorReading.create!(sensor: sensor, value: 3.0, unit: "mm", reading_type: "precipitation", recorded_at: 10.minutes.ago)

    alarm = Alarm.new(
      name: "Window Test Alarm #{suffix}", alarm_type: "metric", enabled: true,
      river_basin: basin, metric_name: "precipitation", statistic: "Sum",
      period_seconds: 3600, evaluation_periods: 3, datapoints_to_alarm: 1,
      missing_data_treatment: "missing"
    )
    alarm.alarm_thresholds.build(severity: 1, comparison_operator: "GreaterThanOrEqualToThreshold",
                                  threshold_value: 10.0, unit: "mm")
    alarm.save!

    get admin_alarm_path(alarm)

    assert_select "[data-admin--reading-chart-readings-value]" do |elements|
      readings = JSON.parse(elements.first["data-admin--reading-chart-readings-value"])
      assert_equal 48, readings.length
    end
  end

  test "show honours an explicit range param and clamps it to real data bounds" do
    suffix = SecureRandom.hex(4)
    basin = RiverBasin.create!(name: "Range Test Basin #{suffix}", active: true)
    station = MonitoringStation.create!(
      external_id: "RANGE-TEST-#{suffix}", name: "Range Test Station #{suffix}",
      data_source: "TEST", status: :active, river_basin: basin
    )
    sensor = Sensor.create!(
      monitoring_station: station, sensor_type: :pluviometer, external_id: "RANGE-TEST-PLUV-#{suffix}",
      unit: "mm", reading_type: "precipitation", status: :active
    )
    SensorReading.create!(sensor: sensor, value: 5.0, unit: "mm", reading_type: "precipitation", recorded_at: 5.days.ago)

    alarm = Alarm.new(
      name: "Range Test Alarm #{suffix}", alarm_type: "metric", enabled: true,
      river_basin: basin, metric_name: "precipitation", statistic: "Sum",
      period_seconds: 3600, evaluation_periods: 3, datapoints_to_alarm: 1,
      missing_data_treatment: "missing"
    )
    alarm.alarm_thresholds.build(severity: 1, comparison_operator: "GreaterThanOrEqualToThreshold",
                                  threshold_value: 10.0, unit: "mm")
    alarm.save!

    get admin_alarm_path(alarm, range: { from: 6.days.ago.iso8601, to: 4.days.ago.iso8601 })

    assert_select "[data-testid='alarm-history']" do
      assert_select "input[name='range[from]'][min][max]"
      assert_select "input[name='range[to]'][min][max]"
    end
  end

  test "show renders the chart (not the empty state) when readings are confirmed zero, not missing" do
    # A pluviometer with no rain reports real 0.0 readings — that's data, not an
    # absence of it. Only a genuinely missing period (nil) should hit the empty state.
    suffix = SecureRandom.hex(4)
    basin = RiverBasin.create!(name: "Chart Test Basin #{suffix}", active: true)
    station = MonitoringStation.create!(
      external_id: "CHART-TEST-#{suffix}", name: "Chart Test Station #{suffix}",
      data_source: "TEST", status: :active, river_basin: basin
    )
    sensor = Sensor.create!(
      monitoring_station: station, sensor_type: :pluviometer, external_id: "CHART-TEST-PLUV-#{suffix}",
      unit: "mm", reading_type: "precipitation", status: :active
    )
    SensorReading.create!(sensor: sensor, value: 0.0, unit: "mm", reading_type: "precipitation", recorded_at: 10.minutes.ago)

    alarm = Alarm.new(
      name: "Chart Test Alarm #{suffix}", alarm_type: "metric", enabled: true,
      river_basin: basin, metric_name: "precipitation", statistic: "Sum",
      period_seconds: 3600, evaluation_periods: 1, datapoints_to_alarm: 1,
      missing_data_treatment: "missing"
    )
    alarm.alarm_thresholds.build(severity: 1, comparison_operator: "GreaterThanOrEqualToThreshold",
                                  threshold_value: 10.0, unit: "mm")
    alarm.save!

    get admin_alarm_path(alarm)

    assert_select "[data-testid='alarm-history']" do
      assert_select "[data-controller~='admin--reading-chart']"
      assert_select "div", text: /Sem dados no período/, count: 0
    end
  end

  test "show renders the empty state when there is no chart data at all" do
    alarm = alarms(:disabled_alarm) # no river_basin set
    assert alarm.river_basin.blank?, "fixture precondition"

    get admin_alarm_path(alarm)

    assert_select "[data-testid='alarm-history']" do
      assert_select "[data-controller~='admin--reading-chart']", count: 0
      assert_select "div", text: /Sem dados no período/
      assert_select "p", text: /Última leitura/, count: 0
    end
  end

  test "show shows the last known reading time when the chart window is fully empty" do
    # A station whose last reading predates the whole 48h chart window (a long outage) —
    # the empty state should say when data was last actually received, not leave it blank.
    suffix = SecureRandom.hex(4)
    basin = RiverBasin.create!(name: "Stale Chart Basin #{suffix}", active: true)
    station = MonitoringStation.create!(
      external_id: "STALE-CHART-#{suffix}", name: "Stale Chart Station #{suffix}",
      data_source: "TEST", status: :active, river_basin: basin
    )
    sensor = Sensor.create!(
      monitoring_station: station, sensor_type: :pluviometer, external_id: "STALE-CHART-PLUV-#{suffix}",
      unit: "mm", reading_type: "precipitation", status: :active
    )
    SensorReading.create!(sensor: sensor, value: 5.0, unit: "mm", reading_type: "precipitation", recorded_at: 3.days.ago)

    alarm = Alarm.new(
      name: "Stale Chart Alarm #{suffix}", alarm_type: "metric", enabled: true,
      river_basin: basin, metric_name: "precipitation", statistic: "Sum",
      period_seconds: 3600, evaluation_periods: 1, datapoints_to_alarm: 1,
      missing_data_treatment: "missing"
    )
    alarm.alarm_thresholds.build(severity: 1, comparison_operator: "GreaterThanOrEqualToThreshold",
                                  threshold_value: 10.0, unit: "mm")
    alarm.save!

    get admin_alarm_path(alarm)

    assert_select "[data-testid='alarm-history']" do
      assert_select "[data-controller~='admin--reading-chart']", count: 0
      assert_select "div", text: /Sem dados no período/
      assert_select "p", text: /Última leitura/
    end
  end

  test "show renders the current evaluation card with per-tier breach counts" do
    get admin_alarm_path(alarms(:flood_alert_belem))
    assert_select "[data-testid='alarm-evaluation']" do
      assert_select "[data-testid='alarm-evaluation-tier-2']", text: /Disparado/
      assert_select "[data-testid='alarm-evaluation-tier-3']", text: /Disparado/
    end
  end

  test "show renders the recent datapoints table with values from last_datapoints" do
    get admin_alarm_path(alarms(:flood_alert_belem))
    assert_select "[data-testid='alarm-datapoints']" do
      assert_select "td", text: /65[\.,]00/
      assert_select "td", text: /62[\.,]00/
      assert_select "td", text: /45[\.,]00/
    end
  end

  test "show shows the awaiting-evaluation empty state when last_datapoints is blank" do
    alarm = alarms(:disabled_alarm) # has 1 threshold but no last_datapoints
    assert alarm.last_datapoints.blank?, "fixture precondition"

    get admin_alarm_path(alarm)
    assert_response :success
    assert_select "[data-testid='alarm-evaluation']", text: /Aguardando primeira avaliação/
    assert_select "[data-testid='alarm-datapoints']", count: 0
  end

  # ── New ──

  test "new renders successfully" do
    get new_admin_alarm_path
    assert_response :success
  end

  test "new displays form fields" do
    get new_admin_alarm_path
    assert_select "form" do
      assert_select "input[name='alarm[name]']"
      assert_select "input[name='alarm[alarm_type]'][value='metric']"
    end
  end

  test "new form explains Vigilância as the implicit baseline below all threshold bands" do
    get new_admin_alarm_path
    assert_select "p", text: /Vigilância/
  end

  test "new form's metric dropdown offers exactly the two real metrics" do
    get new_admin_alarm_path
    assert_select "select[name='alarm[metric_name]']" do
      assert_select "option", text: "Score de Risco", count: 0
      assert_select "option", text: "Precipitação"
      assert_select "option", text: "Previsão de Precipitação"
      # include_blank + the 2 real options, nothing else
      assert_select "option", count: 3
    end
  end

  test "edit form explains Vigilância as the implicit baseline below all threshold bands" do
    get edit_admin_alarm_path(alarms(:precip_3h_belem))
    assert_select "p", text: /Vigilância/
  end

  test "edit displays a station dropdown listing stations configured for some basin" do
    get edit_admin_alarm_path(alarms(:precip_3h_belem))
    configured_station_count = MonitoringStation.joins(:river_basin_monitoring_stations).distinct.count
    assert_select "select[name='alarm[monitoring_station_id]']" do
      # +1 for the blank "— Todas as estações da bacia —" option
      assert_select "option", count: configured_station_count + 1
    end
  end

  # ── Create ──

  test "create with valid params creates alarm and redirects" do
    assert_difference "Alarm.count", 1 do
      post admin_alarms_path, params: {
        alarm: {
          name: "Novo Alarme Teste",
          alarm_type: "metric",
          enabled: true,
          metric_name: "precipitation",
          statistic: "Sum",
          period_seconds: 3600,
          evaluation_periods: 1,
          datapoints_to_alarm: 1,
          missing_data_treatment: "missing",
          alarm_thresholds_attributes: {
            "0" => { severity: 2, comparison_operator: "GreaterThanThreshold", threshold_value: 50.0, unit: "mm" }
          }
        }
      }
    end
    assert_redirected_to admin_alarm_path(Alarm.last)
    assert_equal 1, Alarm.last.alarm_thresholds.count
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "Alarm.count" do
      post admin_alarms_path, params: {
        alarm: { name: "", alarm_type: "metric" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create alarms" do
    sign_in_as users(:operator)
    post admin_alarms_path, params: {
      alarm: { name: "Proibido", alarm_type: "metric" }
    }
    assert_redirected_to admin_root_path
  end

  test "coordinator can create alarms" do
    sign_in_as users(:coordinator)
    assert_difference "Alarm.count", 1 do
      post admin_alarms_path, params: {
        alarm: {
          name: "Alarme do Coordenador",
          alarm_type: "metric",
          metric_name: "precipitation",
          statistic: "Sum",
          period_seconds: 3600,
          evaluation_periods: 1,
          datapoints_to_alarm: 1,
          missing_data_treatment: "missing",
          alarm_thresholds_attributes: {
            "0" => { severity: 1, comparison_operator: "GreaterThanThreshold", threshold_value: 10.0, unit: "mm" }
          }
        }
      }
    end
  end

  # ── Edit / Update ──

  test "edit renders successfully" do
    get edit_admin_alarm_path(alarms(:precip_3h_belem))
    assert_response :success
  end

  test "update with valid params updates alarm and redirects" do
    alarm = alarms(:precip_3h_belem)
    patch admin_alarm_path(alarm), params: {
      alarm: { name: "Alarme Atualizado" }
    }
    assert_redirected_to admin_alarm_path(alarm)
    assert_equal "Alarme Atualizado", alarm.reload.name
  end

  test "update can scope the alarm to a specific station configured for its basin" do
    alarm = alarms(:precip_3h_belem) # river_basin: bacia_belem
    station = monitoring_stations(:estacao_belem) # configured for bacia_belem

    patch admin_alarm_path(alarm), params: {
      alarm: { monitoring_station_id: station.id }
    }

    assert_redirected_to admin_alarm_path(alarm)
    assert_equal station, alarm.reload.monitoring_station
  end

  test "update rejects a station not configured for the alarm's basin" do
    alarm = alarms(:precip_3h_belem) # river_basin: bacia_belem
    foreign_station = monitoring_stations(:estacao_barigui) # configured for bacia_barigui

    patch admin_alarm_path(alarm), params: {
      alarm: { monitoring_station_id: foreign_station.id }
    }

    assert_response :unprocessable_entity
    assert_nil alarm.reload.monitoring_station
  end

  test "operator cannot update alarms" do
    sign_in_as users(:operator)
    patch admin_alarm_path(alarms(:precip_3h_belem)), params: {
      alarm: { name: "Tentativa" }
    }
    assert_redirected_to admin_root_path
  end

  # ── Destroy ──

  test "admin can destroy alarm" do
    alarm = alarms(:disabled_alarm)
    assert_difference "Alarm.count", -1 do
      delete admin_alarm_path(alarm)
    end
    assert_redirected_to admin_alarms_path
  end

  test "operator cannot destroy alarms" do
    sign_in_as users(:operator)
    assert_no_difference "Alarm.count" do
      delete admin_alarm_path(alarms(:disabled_alarm))
    end
    assert_redirected_to admin_root_path
  end

  test "coordinator cannot destroy alarms" do
    sign_in_as users(:coordinator)
    assert_no_difference "Alarm.count" do
      delete admin_alarm_path(alarms(:disabled_alarm))
    end
    assert_redirected_to admin_root_path
  end

  test "show displays the severity change in the history timeline" do
    # Fixture alarm_transition: flood_alert_belem's history row records previous_severity: 0
    # (Vigilância), new_severity: 3 (Alarme).
    get admin_alarm_path(alarms(:flood_alert_belem))
    assert_select "[data-testid='alarm-history']" do
      assert_select "span", text: "Vigilância"
    end
  end

  test "show never renders a state badge chain in the history timeline" do
    alarm = alarms(:flood_alert_belem)
    alarm.alarm_state_histories.destroy_all
    alarm.alarm_state_histories.create!(
      previous_state: "ok", new_state: "alarm",
      previous_severity: 0, new_severity: 2,
      reason: "entered alarm", evaluated_at: Time.current
    )

    get admin_alarm_path(alarm)

    assert_select "[data-testid='state-chain']", count: 0
  end

  test "show shows a Dados insuficientes badge instead of a bare dash for unknown severity" do
    # A transition out of insufficient_data always has previous_severity: nil (its severity is
    # never tracked) — the history row must explain that, not show an unexplained dash.
    alarm = alarms(:flood_alert_belem)
    alarm.alarm_state_histories.destroy_all
    alarm.alarm_state_histories.create!(
      previous_state: "insufficient_data", new_state: "ok",
      previous_severity: nil, new_severity: 0,
      reason: "dados restabelecidos", evaluated_at: Time.current
    )

    get admin_alarm_path(alarm)

    assert_select "[data-testid='alarm-history']" do
      assert_select "span", text: "Dados insuficientes"
      assert_select "span", text: "—", count: 0
    end
  end

  test "show never renders an empty row, even when both severities are nil" do
    # Stale rows from before "ok" always got an explicit severity of 0 can have
    # previous_severity: nil AND new_severity: nil — the chain must still render.
    alarm = alarms(:flood_alert_belem)
    alarm.alarm_state_histories.destroy_all
    alarm.alarm_state_histories.create!(
      previous_state: "insufficient_data", new_state: "ok",
      previous_severity: nil, new_severity: nil,
      reason: "legacy row", evaluated_at: Time.current
    )

    get admin_alarm_path(alarm)

    assert_select "[data-testid='alarm-history']" do
      assert_select "span", text: "Dados insuficientes", count: 2
    end
  end

  # ── History ──

  test "history renders successfully" do
    get history_admin_alarm_path(alarms(:precip_3h_belem))
    assert_response :success
  end

  test "history page displays the severity change" do
    get history_admin_alarm_path(alarms(:flood_alert_belem))
    assert_select "span", text: "Vigilância"
  end

  test "history page never renders a state badge chain" do
    alarm = alarms(:flood_alert_belem)
    alarm.alarm_state_histories.destroy_all
    alarm.alarm_state_histories.create!(
      previous_state: "ok", new_state: "alarm",
      previous_severity: 0, new_severity: 2,
      reason: "entered alarm", evaluated_at: Time.current
    )

    get history_admin_alarm_path(alarm)

    assert_select "[data-testid='state-chain']", count: 0
  end

  test "history page shows a Dados insuficientes badge instead of a bare dash for unknown severity" do
    alarm = alarms(:flood_alert_belem)
    alarm.alarm_state_histories.destroy_all
    alarm.alarm_state_histories.create!(
      previous_state: "insufficient_data", new_state: "ok",
      previous_severity: nil, new_severity: 0,
      reason: "dados restabelecidos", evaluated_at: Time.current
    )

    get history_admin_alarm_path(alarm)

    assert_select "span", text: "Dados insuficientes"
    assert_select "span", text: "—", count: 0
  end

  test "history page never renders an empty row, even when both severities are nil" do
    alarm = alarms(:flood_alert_belem)
    alarm.alarm_state_histories.destroy_all
    alarm.alarm_state_histories.create!(
      previous_state: "insufficient_data", new_state: "ok",
      previous_severity: nil, new_severity: nil,
      reason: "legacy row", evaluated_at: Time.current
    )

    get history_admin_alarm_path(alarm)

    assert_select "span", text: "Dados insuficientes", count: 2
  end

end
