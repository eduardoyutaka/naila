require "test_helper"

class Admin::RiverBasinsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Index ──

  test "index renders successfully" do
    get admin_river_basins_path
    assert_response :success
  end

  test "index displays river basin names" do
    get admin_river_basins_path
    assert_select "td", text: /Bacia do Rio Belém/
    assert_select "td", text: /Bacia do Rio Barigui/
  end

  test "index shows summary cards with counts" do
    get admin_river_basins_path
    assert_select "[data-testid='summary-total-count']"
    assert_select "[data-testid='summary-active-count']"
    assert_select "[data-testid='summary-at-risk-count']"
  end

  test "index shows risk level badges" do
    get admin_river_basins_path
    assert_select "span", text: "Alerta"
    assert_select "span", text: "Normal"
  end

  test "index shows empty state when no basins exist" do
    RiverBasin.destroy_all
    get admin_river_basins_path
    assert_select "div", text: /Nenhuma bacia hidrográfica cadastrada/
  end

  test "index requires authentication" do
    reset!
    get admin_river_basins_path
    assert_redirected_to login_path
  end

  # ── Show ──

  test "show renders successfully" do
    get admin_river_basin_path(river_basins(:bacia_belem))
    assert_response :success
  end

  test "show displays basin name" do
    get admin_river_basin_path(river_basins(:bacia_belem))
    assert_select "h1", text: /Bacia do Rio Belém/
  end

  test "show displays risk level badge" do
    get admin_river_basin_path(river_basins(:bacia_belem))
    assert_select "span", text: "Alerta"
  end

  test "show displays details section" do
    get admin_river_basin_path(river_basins(:bacia_belem))
    assert_select "[data-testid='basin-details']"
  end

  test "show displays map with polygon viewer" do
    get admin_river_basin_path(river_basins(:bacia_belem))
    assert_select "[data-controller='admin--polygon-viewer']"
  end

  # ── New ──

  test "new renders successfully" do
    get new_admin_river_basin_path
    assert_response :success
  end

  test "new displays form fields" do
    get new_admin_river_basin_path
    assert_select "form" do
      assert_select "input[name='river_basin[name]']"
      assert_select "input[name='river_basin[area_km2]']"
      assert_select "textarea[name='river_basin[description]']"
      assert_select "input[name='river_basin[geometry_geojson]']"
    end
  end

  # ── Create ──

  test "create with valid params creates basin and redirects" do
    assert_difference "RiverBasin.count", 1 do
      post admin_river_basins_path, params: {
        river_basin: {
          name: "Nova Bacia Teste"
        }
      }
    end
    assert_redirected_to admin_river_basin_path(RiverBasin.last)
  end

  test "create with GeoJSON geometry stores polygon" do
    geojson = '{"type":"Polygon","coordinates":[[[-49.28,-25.43],[-49.27,-25.43],[-49.27,-25.42],[-49.28,-25.42],[-49.28,-25.43]]]}'
    post admin_river_basins_path, params: {
      river_basin: {
        name: "Bacia com Geometria",
        geometry_geojson: geojson
      }
    }
    basin = RiverBasin.last
    assert_not_nil basin.geometry
  end

  test "create with invalid params renders new with 422" do
    assert_no_difference "RiverBasin.count" do
      post admin_river_basins_path, params: {
        river_basin: { name: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "operator cannot create river basins" do
    sign_in_as users(:operator)
    post admin_river_basins_path, params: {
      river_basin: { name: "Proibida" }
    }
    assert_redirected_to admin_root_path
  end

  test "coordinator can create river basins" do
    sign_in_as users(:coordinator)
    assert_difference "RiverBasin.count", 1 do
      post admin_river_basins_path, params: {
        river_basin: { name: "Bacia do Coordenador" }
      }
    end
    assert_redirected_to admin_river_basin_path(RiverBasin.last)
  end

  # ── Edit / Update ──

  test "edit renders successfully" do
    get edit_admin_river_basin_path(river_basins(:bacia_barigui))
    assert_response :success
  end

  test "update with valid params updates basin and redirects" do
    patch admin_river_basin_path(river_basins(:bacia_barigui)), params: {
      river_basin: { name: "Bacia Barigui Atualizada" }
    }
    assert_redirected_to admin_river_basin_path(river_basins(:bacia_barigui))
    assert_equal "Bacia Barigui Atualizada", river_basins(:bacia_barigui).reload.name
  end

  test "operator cannot update river basins" do
    sign_in_as users(:operator)
    patch admin_river_basin_path(river_basins(:bacia_barigui)), params: {
      river_basin: { name: "Tentativa" }
    }
    assert_redirected_to admin_root_path
  end

  # ── Destroy ──

  test "admin can destroy river basin" do
    assert_difference "RiverBasin.count", -1 do
      delete admin_river_basin_path(river_basins(:bacia_barigui))
    end
    assert_redirected_to admin_river_basins_path
  end

  test "operator cannot destroy river basins" do
    sign_in_as users(:operator)
    assert_no_difference "RiverBasin.count" do
      delete admin_river_basin_path(river_basins(:bacia_barigui))
    end
    assert_redirected_to admin_root_path
  end

  test "coordinator cannot destroy river basins" do
    sign_in_as users(:coordinator)
    assert_no_difference "RiverBasin.count" do
      delete admin_river_basin_path(river_basins(:bacia_barigui))
    end
    assert_redirected_to admin_root_path
  end
end
