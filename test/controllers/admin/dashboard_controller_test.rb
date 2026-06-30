require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "dashboard index loads successfully" do
    get admin_root_path
    assert_response :success
  end

  test "dashboard passes sensor stations data to map" do
    get admin_root_path
    assert_response :success
    assert_select "[data-admin--map-sensors-value]"
  end

  test "dashboard sensor data includes only stations with location" do
    get admin_root_path
    sensor_json = css_select("[data-admin--map-sensors-value]").first["data-admin--map-sensors-value"]
    sensors = JSON.parse(sensor_json)

    sensor_names = sensors.map { |s| s["name"] }
    assert_includes sensor_names, "Estação Belém — Centro Cívico"
    assert_includes sensor_names, "Estação Barigui — Parque Barigui"
  end

  test "dashboard shows weather summary section" do
    get admin_root_path
    assert_response :success
    assert_select "[data-testid='weather-summary']"
  end

  test "dashboard weather summary shows forecast precipitation" do
    get admin_root_path
    assert_select "[data-testid='forecast-precipitation']"
  end

  test "dashboard sensor data contains required fields" do
    get admin_root_path
    sensor_json = css_select("[data-admin--map-sensors-value]").first["data-admin--map-sensors-value"]
    sensors = JSON.parse(sensor_json)
    station = sensors.find { |s| s["name"] == "Estação Belém — Centro Cívico" }

    assert_not_nil station
    assert_includes station["sensor_types"], "pluviometer"
    assert_equal "active", station["status"]
    assert_in_delta(-25.405, station["lat"], 0.01)
    assert_in_delta(-49.270, station["lng"], 0.01)
    assert_equal "Centro", station["neighborhood"]
  end

  test "dashboard replaces the Sensores Online card with a Vigilância card" do
    get admin_root_path
    assert_response :success

    # Scope to the summary cards grid — "Sensores Online" / .text-sensor-online also appear
    # in the sidebar (part of the layout), so the check must be local to the cards.
    assert_select "[data-testid=summary-cards]" do
      # The old "Sensores Online" summary card (its count used .text-sensor-online) is gone.
      assert_select ".text-sensor-online", count: 0

      # The lowest severity level (Vigilância = 0) is now a summary card styled like the
      # other severity cards, with a left border in the normal-severity color.
      assert_select "div.border-l-risk-normal", { text: /Vigilância/ },
        "expected a Vigilância summary card with the normal-severity left border"
    end
  end

  test "dashboard Vigilância card counts enabled alarms in the ok (monitoring) state" do
    get admin_root_path
    assert_response :success

    # Fixtures: only precip_3h_belem is enabled + ok → the severity-0 (Vigilância) bucket = 1.
    assert_equal 1, Alarm.enabled.by_state("ok").count
    assert_select "div.border-l-risk-normal .tabular-nums", text: "1"
  end

  test "dashboard shows a Sensores Ativos card with active over total sensor count" do
    get admin_root_path
    assert_response :success

    # Fixtures: 2 active sensors (pluv_cemaden_centro, pluv_belem) out of 3 total.
    assert_equal 2, Sensor.online.count
    assert_equal 3, Sensor.count

    assert_select "[data-testid=summary-cards]" do
      assert_select "div", { text: /Sensores Ativos/ }, "expected a Sensores Ativos card"
      assert_select "div.tabular-nums", { text: /2\/3/ },
        "expected the card to show active/total as 2/3"
      # The old "Bacias Monitoradas" card is gone.
      assert_select "div", { text: "Bacias Monitoradas", count: 0 }
    end
  end
end
