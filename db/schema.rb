# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_21_000024) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

  create_table "alert_notifications", force: :cascade do |t|
    t.bigint "alert_id", null: false
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.text "failure_reason"
    t.jsonb "metadata", default: {}
    t.string "recipient"
    t.datetime "sent_at"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["alert_id", "channel"], name: "index_alert_notifications_on_alert_id_and_channel"
    t.index ["alert_id"], name: "index_alert_notifications_on_alert_id"
    t.index ["status"], name: "index_alert_notifications_on_status"
  end

  create_table "alert_thresholds", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "comparison", null: false
    t.integer "cooldown_minutes", default: 60
    t.datetime "created_at", null: false
    t.string "parameter", null: false
    t.bigint "risk_zone_id"
    t.bigint "river_id"
    t.integer "severity", null: false
    t.string "threshold_type", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.float "value", null: false
    t.index ["risk_zone_id"], name: "index_alert_thresholds_on_risk_zone_id"
    t.index ["river_id"], name: "index_alert_thresholds_on_river_id"
  end

  create_table "alerts", force: :cascade do |t|
    t.datetime "acknowledged_at"
    t.datetime "activated_at"
    t.st_polygon "affected_area", srid: 4326
    t.bigint "alert_threshold_id"
    t.string "alert_type", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description", null: false
    t.datetime "expires_at"
    t.text "instructions"
    t.bigint "neighborhood_id"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.bigint "risk_zone_id"
    t.bigint "river_id"
    t.integer "severity", null: false
    t.string "status", default: "active"
    t.string "title", null: false
    t.jsonb "trigger_data", default: {}
    t.datetime "updated_at", null: false
    t.index ["affected_area"], name: "index_alerts_on_affected_area", using: :gist
    t.index ["alert_threshold_id"], name: "index_alerts_on_alert_threshold_id"
    t.index ["created_by_id"], name: "index_alerts_on_created_by_id"
    t.index ["neighborhood_id"], name: "index_alerts_on_neighborhood_id"
    t.index ["resolved_by_id"], name: "index_alerts_on_resolved_by_id"
    t.index ["risk_zone_id"], name: "index_alerts_on_risk_zone_id"
    t.index ["river_id"], name: "index_alerts_on_river_id"
    t.index ["severity"], name: "index_alerts_on_severity"
    t.index ["status", "severity"], name: "index_alerts_on_status_and_severity"
    t.index ["status"], name: "index_alerts_on_status"
  end

  create_table "data_sources", force: :cascade do |t|
    t.string "base_url"
    t.jsonb "configuration", default: {}
    t.integer "consecutive_failures", default: 0
    t.datetime "created_at", null: false
    t.integer "fetch_interval_seconds", default: 600
    t.datetime "last_failed_fetch_at"
    t.datetime "last_successful_fetch_at"
    t.string "name", null: false
    t.string "source_type", null: false
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
  end

  create_table "drainage_basins", force: :cascade do |t|
    t.float "area_km2"
    t.st_polygon "boundary", srid: 4326
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["boundary"], name: "index_drainage_basins_on_boundary", using: :gist
  end

  create_table "escalation_rules", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.integer "escalation_after_minutes", null: false
    t.integer "from_severity", null: false
    t.boolean "notify_supervisor", default: false
    t.string "supervisor_contact"
    t.integer "to_severity", null: false
    t.datetime "updated_at", null: false
  end

  create_table "evacuation_routes", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "description"
    t.string "destination_name"
    t.st_point "destination_point", srid: 4326
    t.string "name", null: false
    t.st_line_string "path", srid: 4326
    t.bigint "risk_zone_id"
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_evacuation_routes_on_path", using: :gist
    t.index ["risk_zone_id"], name: "index_evacuation_routes_on_risk_zone_id"
  end

  create_table "neighborhoods", force: :cascade do |t|
    t.float "area_km2"
    t.st_polygon "boundary", srid: 4326
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "current_risk_level", default: 0
    t.string "name", null: false
    t.integer "population"
    t.bigint "region_id"
    t.datetime "updated_at", null: false
    t.index ["boundary"], name: "index_neighborhoods_on_boundary", using: :gist
    t.index ["code"], name: "index_neighborhoods_on_code", unique: true
    t.index ["current_risk_level"], name: "index_neighborhoods_on_current_risk_level"
    t.index ["region_id"], name: "index_neighborhoods_on_region_id"
  end

  create_table "regions", force: :cascade do |t|
    t.st_polygon "boundary", srid: 4326
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["boundary"], name: "index_regions_on_boundary", using: :gist
    t.index ["code"], name: "index_regions_on_code", unique: true
  end

  create_table "risk_assessments", force: :cascade do |t|
    t.datetime "assessed_at", null: false
    t.jsonb "contributing_factors", default: {}
    t.datetime "created_at", null: false
    t.float "forecast_score"
    t.float "precipitation_score"
    t.integer "risk_level", null: false
    t.float "risk_score", null: false
    t.bigint "risk_zone_id", null: false
    t.float "river_level_score"
    t.jsonb "sensor_data_snapshot", default: {}
    t.float "soil_moisture_score"
    t.datetime "updated_at", null: false
    t.index ["risk_level"], name: "index_risk_assessments_on_risk_level"
    t.index ["risk_zone_id", "assessed_at"], name: "index_risk_assessments_on_risk_zone_id_and_assessed_at"
    t.index ["risk_zone_id"], name: "index_risk_assessments_on_risk_zone_id"
  end

  create_table "risk_zones", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "base_risk_level", default: 0
    t.datetime "created_at", null: false
    t.integer "current_risk_level", default: 0
    t.float "current_risk_score"
    t.bigint "drainage_basin_id"
    t.st_polygon "geometry", srid: 4326
    t.string "name", null: false
    t.bigint "neighborhood_id"
    t.jsonb "risk_factors", default: {}
    t.datetime "risk_updated_at"
    t.datetime "updated_at", null: false
    t.string "zone_type", null: false
    t.index ["current_risk_level"], name: "index_risk_zones_on_current_risk_level"
    t.index ["drainage_basin_id"], name: "index_risk_zones_on_drainage_basin_id"
    t.index ["geometry"], name: "index_risk_zones_on_geometry", using: :gist
    t.index ["neighborhood_id"], name: "index_risk_zones_on_neighborhood_id"
    t.index ["zone_type"], name: "index_risk_zones_on_zone_type"
  end

  create_table "rivers", force: :cascade do |t|
    t.float "alert_level_m"
    t.st_line_string "course", srid: 4326
    t.datetime "created_at", null: false
    t.bigint "drainage_basin_id"
    t.float "flood_level_m"
    t.float "length_km"
    t.string "name", null: false
    t.float "normal_level_m"
    t.float "overflow_level_m"
    t.datetime "updated_at", null: false
    t.index ["course"], name: "index_rivers_on_course", using: :gist
    t.index ["drainage_basin_id"], name: "index_rivers_on_drainage_basin_id"
  end

  create_table "satellite_observations", force: :cascade do |t|
    t.datetime "captured_at", null: false
    t.st_polygon "coverage_area", srid: 4326
    t.datetime "created_at", null: false
    t.string "image_url"
    t.jsonb "metadata", default: {}
    t.string "observation_type", null: false
    t.string "source", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.float "value"
    t.index ["coverage_area"], name: "index_satellite_observations_on_coverage_area", using: :gist
    t.index ["source", "captured_at"], name: "index_satellite_observations_on_source_and_captured_at"
  end

  create_table "sensor_readings", primary_key: ["id", "recorded_at"], options: "PARTITION BY RANGE (recorded_at)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigserial "id", null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "index_sensor_readings_on_reading_type"
    t.index ["sensor_station_id", "recorded_at"], name: "index_sensor_readings_on_sensor_station_id_and_recorded_at"
    t.index ["sensor_station_id"], name: "index_sensor_readings_on_sensor_station_id"
  end

  create_table "sensor_readings_2026_01", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_01_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_01_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_01_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_02", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_02_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_02_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_02_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_03", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_03_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_03_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_03_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_04", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_04_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_04_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_04_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_05", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_05_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_05_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_05_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_06", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_06_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_06_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_06_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_07", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_07_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_07_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_07_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_08", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_08_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_08_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_08_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_09", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_09_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_09_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_09_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_10", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_10_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_10_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_10_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_11", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_11_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_11_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_11_sensor_station_id_idx"
  end

  create_table "sensor_readings_2026_12", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2026_12_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2026_12_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2026_12_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_01", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_01_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_01_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_01_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_02", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_02_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_02_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_02_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_03", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_03_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_03_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_03_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_04", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_04_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_04_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_04_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_05", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_05_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_05_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_05_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_06", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_06_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_06_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_06_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_07", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_07_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_07_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_07_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_08", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_08_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_08_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_08_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_09", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_09_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_09_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_09_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_10", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_10_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_10_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_10_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_11", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_11_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_11_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_11_sensor_station_id_idx"
  end

  create_table "sensor_readings_2027_12", primary_key: ["id", "recorded_at"], options: "INHERITS (sensor_readings)", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "id", default: -> { "nextval('sensor_readings_id_seq'::regclass)" }, null: false
    t.string "quality_flag", limit: 10, default: "ok"
    t.jsonb "raw_payload", default: {}
    t.string "reading_type", limit: 30, null: false
    t.timestamptz "recorded_at", null: false
    t.bigint "sensor_station_id", null: false
    t.string "unit", limit: 20, null: false
    t.float "value", null: false
    t.index ["reading_type"], name: "sensor_readings_2027_12_reading_type_idx"
    t.index ["sensor_station_id", "recorded_at"], name: "sensor_readings_2027_12_sensor_station_id_recorded_at_idx"
    t.index ["sensor_station_id"], name: "sensor_readings_2027_12_sensor_station_id_idx"
  end

  create_table "sensor_stations", force: :cascade do |t|
    t.string "api_token_digest"
    t.datetime "created_at", null: false
    t.string "data_source", null: false
    t.bigint "drainage_basin_id"
    t.float "elevation_m"
    t.string "external_id", null: false
    t.datetime "last_reading_at"
    t.float "last_reading_value"
    t.st_point "location", srid: 4326
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.bigint "neighborhood_id"
    t.bigint "river_id"
    t.string "station_type", null: false
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["drainage_basin_id"], name: "index_sensor_stations_on_drainage_basin_id"
    t.index ["external_id", "data_source"], name: "index_sensor_stations_on_external_id_and_data_source", unique: true
    t.index ["location"], name: "index_sensor_stations_on_location", using: :gist
    t.index ["neighborhood_id"], name: "index_sensor_stations_on_neighborhood_id"
    t.index ["river_id"], name: "index_sensor_stations_on_river_id"
    t.index ["station_type"], name: "index_sensor_stations_on_station_type"
    t.index ["status"], name: "index_sensor_stations_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "department"
    t.string "email_address", null: false
    t.string "name", null: false
    t.jsonb "notification_preferences", default: {}
    t.string "password_digest", null: false
    t.string "phone_number"
    t.boolean "receives_sms_alerts", default: true
    t.string "role", default: "operator", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "weather_forecasts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "issued_at", null: false
    t.st_point "location", srid: 4326
    t.float "precipitation_mm"
    t.float "precipitation_probability"
    t.jsonb "raw_data", default: {}
    t.string "severity"
    t.string "source", null: false
    t.float "temperature_max_c"
    t.float "temperature_min_c"
    t.datetime "updated_at", null: false
    t.datetime "valid_from", null: false
    t.datetime "valid_until", null: false
    t.index ["location"], name: "index_weather_forecasts_on_location", using: :gist
    t.index ["source", "valid_from"], name: "index_weather_forecasts_on_source_and_valid_from"
  end

  create_table "weather_observations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "humidity_pct"
    t.st_point "location", srid: 4326
    t.datetime "observed_at", null: false
    t.float "precipitation_mm"
    t.float "precipitation_rate_mm_h"
    t.float "pressure_hpa"
    t.jsonb "raw_data", default: {}
    t.string "source", null: false
    t.string "station_code"
    t.float "temperature_c"
    t.datetime "updated_at", null: false
    t.string "weather_condition"
    t.float "wind_direction_deg"
    t.float "wind_speed_ms"
    t.index ["location"], name: "index_weather_observations_on_location", using: :gist
    t.index ["source", "observed_at"], name: "index_weather_observations_on_source_and_observed_at"
  end

  add_foreign_key "alert_notifications", "alerts"
  add_foreign_key "alert_thresholds", "risk_zones"
  add_foreign_key "alert_thresholds", "rivers"
  add_foreign_key "alerts", "alert_thresholds"
  add_foreign_key "alerts", "neighborhoods"
  add_foreign_key "alerts", "risk_zones"
  add_foreign_key "alerts", "rivers"
  add_foreign_key "alerts", "users", column: "created_by_id"
  add_foreign_key "alerts", "users", column: "resolved_by_id"
  add_foreign_key "evacuation_routes", "risk_zones"
  add_foreign_key "neighborhoods", "regions"
  add_foreign_key "risk_assessments", "risk_zones"
  add_foreign_key "risk_zones", "drainage_basins"
  add_foreign_key "risk_zones", "neighborhoods"
  add_foreign_key "rivers", "drainage_basins"
  add_foreign_key "sensor_readings", "sensor_stations"
  add_foreign_key "sensor_readings_2026_01", "sensor_stations"
  add_foreign_key "sensor_readings_2026_02", "sensor_stations"
  add_foreign_key "sensor_readings_2026_03", "sensor_stations"
  add_foreign_key "sensor_readings_2026_04", "sensor_stations"
  add_foreign_key "sensor_readings_2026_05", "sensor_stations"
  add_foreign_key "sensor_readings_2026_06", "sensor_stations"
  add_foreign_key "sensor_readings_2026_07", "sensor_stations"
  add_foreign_key "sensor_readings_2026_08", "sensor_stations"
  add_foreign_key "sensor_readings_2026_09", "sensor_stations"
  add_foreign_key "sensor_readings_2026_10", "sensor_stations"
  add_foreign_key "sensor_readings_2026_11", "sensor_stations"
  add_foreign_key "sensor_readings_2026_12", "sensor_stations"
  add_foreign_key "sensor_readings_2027_01", "sensor_stations"
  add_foreign_key "sensor_readings_2027_02", "sensor_stations"
  add_foreign_key "sensor_readings_2027_03", "sensor_stations"
  add_foreign_key "sensor_readings_2027_04", "sensor_stations"
  add_foreign_key "sensor_readings_2027_05", "sensor_stations"
  add_foreign_key "sensor_readings_2027_06", "sensor_stations"
  add_foreign_key "sensor_readings_2027_07", "sensor_stations"
  add_foreign_key "sensor_readings_2027_08", "sensor_stations"
  add_foreign_key "sensor_readings_2027_09", "sensor_stations"
  add_foreign_key "sensor_readings_2027_10", "sensor_stations"
  add_foreign_key "sensor_readings_2027_11", "sensor_stations"
  add_foreign_key "sensor_readings_2027_12", "sensor_stations"
  add_foreign_key "sensor_stations", "drainage_basins"
  add_foreign_key "sensor_stations", "neighborhoods"
  add_foreign_key "sensor_stations", "rivers"
  add_foreign_key "sessions", "users"
end
