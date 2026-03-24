require "test_helper"

class Admin::RiskZonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_risk_zones_path
    assert_response :success
  end

  test "index displays risk zone names" do
    get admin_risk_zones_path
    assert_select "td", text: /Zona Centro/
    assert_select "td", text: /Zona Batel/
  end

  test "index shows summary cards with counts" do
    get admin_risk_zones_path
    assert_select "[data-testid='summary-total-count']"
    assert_select "[data-testid='summary-active-count']"
    assert_select "[data-testid='summary-at-risk-count']"
  end

  test "index shows zone type badges" do
    get admin_risk_zones_path
    assert_select "span", text: "Planície de Inundação"
    assert_select "span", text: "Encosta"
  end

  test "index shows risk level badges" do
    get admin_risk_zones_path
    assert_select "span", text: "Alerta"
    assert_select "span", text: "Normal"
  end

  test "index shows empty state when no zones exist" do
    RiskZone.destroy_all
    get admin_risk_zones_path
    assert_select "div", text: /Nenhuma zona de risco cadastrada/
  end

  test "index requires authentication" do
    reset!
    get admin_risk_zones_path
    assert_redirected_to login_path
  end

  # ── Show ──

  test "show renders successfully" do
    get admin_risk_zone_path(risk_zones(:zona_centro))
    assert_response :success
  end

  test "show displays zone name" do
    get admin_risk_zone_path(risk_zones(:zona_centro))
    assert_select "h1", text: /Zona Centro/
  end

  test "show displays risk level badge" do
    get admin_risk_zone_path(risk_zones(:zona_centro))
    assert_select "span", text: "Alerta"
  end

  test "show displays details section" do
    get admin_risk_zone_path(risk_zones(:zona_centro))
    assert_select "[data-testid='zone-details']"
  end

  test "show displays map with polygon viewer" do
    get admin_risk_zone_path(risk_zones(:zona_centro))
    assert_select "[data-controller='admin--polygon-viewer']"
  end

  # ── New ──

  test "new renders successfully" do
    get new_admin_risk_zone_path
    assert_response :success
  end

  test "new displays form fields" do
    get new_admin_risk_zone_path
    assert_select "form" do
      assert_select "input[name='risk_zone[name]']"
      assert_select "select[name='risk_zone[zone_type]']"
      assert_select "textarea[name='risk_zone[description]']"
      assert_select "input[name='risk_zone[geometry_geojson]']"
      assert_select "select[name='risk_zone[neighborhood_id]']"
      assert_select "select[name='risk_zone[drainage_basin_id]']"
    end
  end

  # ── Create ──

  test "create with valid params creates zone and redirects" do
    assert_difference "RiskZone.count", 1 do
      post admin_risk_zones_path, params: {
        risk_zone: {
          name: "Nova Zona Teste",
          zone_type: "flood_plain"
        }
      }
    end
    assert_redirected_to admin_risk_zone_path(RiskZone.last)
  end

  test "create with GeoJSON geometry stores polygon" do
    geojson = '{"type":"Polygon","coordinates":[[[-49.28,-25.43],[-49.27,-25.43],[-49.27,-25.42],[-49.28,-25.42],[-49.28,-25.43]]]}'
    post admin_risk_zones_path, params: {
      risk_zone: {
        name: "Zona com Geometria",
        zone_type: "urban_drainage",
        geometry_geojson: geojson
      }
    }
    zone = RiskZone.last
    assert_not_nil zone.geometry
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "RiskZone.count" do
      post admin_risk_zones_path, params: {
        risk_zone: { name: "", zone_type: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create risk zones" do
    sign_in_as users(:operator)
    post admin_risk_zones_path, params: {
      risk_zone: { name: "Proibida", zone_type: "flood_plain" }
    }
    assert_redirected_to admin_root_path
  end

  test "coordinator can create risk zones" do
    sign_in_as users(:coordinator)
    assert_difference "RiskZone.count", 1 do
      post admin_risk_zones_path, params: {
        risk_zone: { name: "Zona do Coordenador", zone_type: "slope" }
      }
    end
    assert_redirected_to admin_risk_zone_path(RiskZone.last)
  end

  # ── Edit / Update ──

  test "edit renders successfully" do
    get edit_admin_risk_zone_path(risk_zones(:zona_batel))
    assert_response :success
  end

  test "update with valid params updates zone and redirects" do
    patch admin_risk_zone_path(risk_zones(:zona_batel)), params: {
      risk_zone: { name: "Zona Batel Atualizada" }
    }
    assert_redirected_to admin_risk_zone_path(risk_zones(:zona_batel))
    assert_equal "Zona Batel Atualizada", risk_zones(:zona_batel).reload.name
  end

  test "operator cannot update risk zones" do
    sign_in_as users(:operator)
    patch admin_risk_zone_path(risk_zones(:zona_batel)), params: {
      risk_zone: { name: "Tentativa" }
    }
    assert_redirected_to admin_root_path
  end

  # ── Destroy ──

  test "admin can destroy risk zone" do
    assert_difference "RiskZone.count", -1 do
      delete admin_risk_zone_path(risk_zones(:zona_batel))
    end
    assert_redirected_to admin_risk_zones_path
  end

  test "operator cannot destroy risk zones" do
    sign_in_as users(:operator)
    assert_no_difference "RiskZone.count" do
      delete admin_risk_zone_path(risk_zones(:zona_batel))
    end
    assert_redirected_to admin_root_path
  end

  test "coordinator cannot destroy risk zones" do
    sign_in_as users(:coordinator)
    assert_no_difference "RiskZone.count" do
      delete admin_risk_zone_path(risk_zones(:zona_batel))
    end
    assert_redirected_to admin_root_path
  end
end
