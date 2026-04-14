# frozen_string_literal: true

# Seed data for Naila — Curitiba Flood Risk Monitoring System
# Run with: bin/rails db:seed
#
# This seed creates realistic demo data including Curitiba's administrative
# regions, key neighborhoods, river basins with polygon boundaries, rivers
# with real threshold levels, sensor stations, sample readings, alerts, and users.

puts "Seeding Naila..."

# ============================================================
# Helper: PostGIS geometry factory (SRID 4326)
# ============================================================
FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)

def point(lon, lat)
  FACTORY.point(lon, lat)
end

def polygon(coords)
  ring = FACTORY.linear_ring(coords.map { |lon, lat| point(lon, lat) })
  FACTORY.polygon(ring)
end

def line_string(coords)
  FACTORY.line_string(coords.map { |lon, lat| point(lon, lat) })
end

# ============================================================
# 1. Administrative Regions
# ============================================================
puts "  Creating regions..."

regions_data = [
  { name: "Matriz",          code: "MTZ" },
  { name: "Boqueirão",       code: "BOQ" },
  { name: "Cajuru",          code: "CJR" },
  { name: "Boa Vista",       code: "BVS" },
  { name: "Santa Felicidade", code: "STF" },
  { name: "Portão",          code: "PRT" },
  { name: "Pinheirinho",     code: "PIN" },
  { name: "Bairro Novo",     code: "BNV" },
  { name: "CIC",             code: "CIC" },
  { name: "Tatuquara",       code: "TAT" },
]

regions = regions_data.map do |data|
  Region.find_or_create_by!(code: data[:code]) do |r|
    r.name = data[:name]
  end
end.index_by(&:code)

# ============================================================
# 2. Key Neighborhoods (subset of Curitiba's 75 bairros)
# ============================================================
puts "  Creating neighborhoods..."

neighborhoods_data = [
  # Matriz region — central, dense, vulnerable to urban drainage
  { name: "Centro",          code: "centro",          region: "MTZ", risk: :normal,    pop: 37_283, area: 3.30 },
  { name: "Centro Cívico",   code: "centro-civico",   region: "MTZ", risk: :normal,    pop: 5_336,  area: 0.97 },
  { name: "São Francisco",   code: "sao-francisco",   region: "MTZ", risk: :normal,    pop: 6_373,  area: 1.21 },
  { name: "Rebouças",        code: "reboucas",        region: "MTZ", risk: :attention, pop: 15_618, area: 2.99 },

  # Boqueirão — Iguaçu river basin, historically flooded
  { name: "Boqueirão",       code: "boqueirao",       region: "BOQ", risk: :attention, pop: 68_495, area: 14.80 },
  { name: "Hauer",           code: "hauer",           region: "BOQ", risk: :normal,    pop: 13_784, area: 4.02 },
  { name: "Alto Boqueirão",  code: "alto-boqueirao",  region: "BOQ", risk: :normal,    pop: 52_441, area: 12.41 },

  # Cajuru — Atuba river, recurrent floods
  { name: "Cajuru",          code: "cajuru",          region: "CJR", risk: :alert,     pop: 96_200, area: 11.58 },
  { name: "Uberaba",         code: "uberaba",         region: "CJR", risk: :attention, pop: 72_056, area: 14.43 },

  # Boa Vista — Barigui river, green areas
  { name: "Boa Vista",       code: "boa-vista",       region: "BVS", risk: :normal,    pop: 29_961, area: 5.34 },
  { name: "Bairro Alto",     code: "bairro-alto",     region: "BVS", risk: :normal,    pop: 46_106, area: 7.03 },
  { name: "Atuba",           code: "atuba",           region: "BVS", risk: :attention, pop: 13_778, area: 4.26 },

  # Santa Felicidade — Barigui headwaters
  { name: "Santa Felicidade", code: "santa-felicidade", region: "STF", risk: :normal, pop: 30_390, area: 12.27 },
  { name: "Cascatinha",      code: "cascatinha",      region: "STF", risk: :normal,    pop: 2_478,  area: 2.59 },

  # Portão
  { name: "Portão",          code: "portao",          region: "PRT", risk: :normal,    pop: 42_662, area: 5.69 },
  { name: "Água Verde",      code: "agua-verde",      region: "PRT", risk: :normal,    pop: 49_866, area: 4.76 },

  # Pinheirinho — Barigui downstream
  { name: "Pinheirinho",     code: "pinheirinho",     region: "PIN", risk: :attention, pop: 50_401, area: 10.74 },
  { name: "Capão Raso",      code: "capao-raso",      region: "PIN", risk: :normal,    pop: 36_065, area: 5.06 },

  # CIC — Barigui industrial, flood-prone
  { name: "Cidade Industrial", code: "cic",           region: "CIC", risk: :attention, pop: 172_573, area: 43.38 },
  { name: "Riviera",         code: "riviera",         region: "CIC", risk: :normal,    pop: 3_295,  area: 3.09 },

  # Bairro Novo — Iguaçu downstream
  { name: "Sítio Cercado",   code: "sitio-cercado",   region: "BNV", risk: :attention, pop: 115_525, area: 11.12 },
  { name: "Ganchinho",       code: "ganchinho",       region: "BNV", risk: :alert,     pop: 8_252,  area: 11.40 },

  # Tatuquara
  { name: "Tatuquara",       code: "tatuquara",       region: "TAT", risk: :attention, pop: 52_780, area: 11.18 },
  { name: "Campo de Santana", code: "campo-de-santana", region: "TAT", risk: :normal,  pop: 32_808, area: 21.59 },
]

neighborhoods = neighborhoods_data.map do |data|
  Neighborhood.find_or_create_by!(code: data[:code]) do |n|
    n.name = data[:name]
    n.region = regions[data[:region]]
    n.current_risk_level = data[:risk]
    n.population = data[:pop]
    n.area_km2 = data[:area]
  end
end.index_by(&:code)

# ============================================================
# 3. River Basins (with polygon boundaries)
# ============================================================
puts "  Creating river basins..."

basins_data = [
  {
    name: "Bacia do Rio Iguaçu", area: 308.0, risk: :attention, score: 0.35,
    coords: [
      [-49.32, -25.44], [-49.28, -25.44], [-49.24, -25.44], [-49.20, -25.45],
      [-49.20, -25.47], [-49.22, -25.49], [-49.26, -25.50], [-49.30, -25.50],
      [-49.32, -25.49], [-49.33, -25.47], [-49.32, -25.44]
    ]
  },
  {
    name: "Bacia do Rio Barigui", area: 131.0, risk: :attention, score: 0.32,
    coords: [
      [-49.36, -25.35], [-49.33, -25.35], [-49.31, -25.37], [-49.29, -25.40],
      [-49.29, -25.43], [-49.30, -25.45], [-49.31, -25.47], [-49.34, -25.47],
      [-49.36, -25.45], [-49.37, -25.42], [-49.37, -25.38], [-49.36, -25.35]
    ]
  },
  {
    name: "Bacia do Rio Belém", area: 87.8, risk: :normal, score: 0.15,
    coords: [
      [-49.28, -25.38], [-49.26, -25.38], [-49.25, -25.40], [-49.25, -25.42],
      [-49.25, -25.44], [-49.26, -25.46], [-49.28, -25.46], [-49.29, -25.44],
      [-49.29, -25.42], [-49.29, -25.40], [-49.28, -25.38]
    ]
  },
  {
    name: "Bacia do Rio Atuba", area: 127.6, risk: :alert, score: 0.48,
    coords: [
      [-49.24, -25.34], [-49.21, -25.35], [-49.19, -25.37], [-49.19, -25.40],
      [-49.20, -25.42], [-49.22, -25.44], [-49.25, -25.44], [-49.26, -25.42],
      [-49.26, -25.39], [-49.25, -25.36], [-49.24, -25.34]
    ]
  },
  {
    name: "Bacia do Rio Passaúna", area: 216.0, risk: :normal, score: 0.10,
    coords: [
      [-49.40, -25.37], [-49.37, -25.37], [-49.36, -25.39], [-49.36, -25.42],
      [-49.37, -25.45], [-49.38, -25.47], [-49.41, -25.47], [-49.42, -25.44],
      [-49.42, -25.41], [-49.41, -25.38], [-49.40, -25.37]
    ]
  },
  {
    name: "Bacia do Ribeirão dos Padilhas", area: 33.0, risk: :attention, score: 0.30,
    coords: [
      [-49.33, -25.48], [-49.31, -25.48], [-49.29, -25.49], [-49.28, -25.51],
      [-49.30, -25.52], [-49.32, -25.52], [-49.34, -25.51], [-49.34, -25.49],
      [-49.33, -25.48]
    ]
  },
]

basins = basins_data.map do |data|
  RiverBasin.find_or_create_by!(name: data[:name]) do |b|
    b.area_km2 = data[:area]
    b.current_risk_level = data[:risk]
    b.current_risk_score = data[:score]
    b.geometry = polygon(data[:coords])
    b.active = true
  end
end.index_by(&:name)

# ============================================================
# 4. Rivers with real threshold levels
# ============================================================
puts "  Creating rivers..."

rivers_data = [
  {
    name: "Rio Iguaçu",
    basin: "Bacia do Rio Iguaçu",
    length: 72.0,
    normal: 1.5, alert: 3.0, flood: 4.5, overflow: 6.0,
    course: [[-49.35, -25.48], [-49.30, -25.47], [-49.25, -25.46], [-49.20, -25.44]]
  },
  {
    name: "Rio Barigui",
    basin: "Bacia do Rio Barigui",
    length: 60.0,
    normal: 1.0, alert: 2.5, flood: 3.5, overflow: 5.0,
    course: [[-49.33, -25.35], [-49.32, -25.38], [-49.30, -25.41], [-49.28, -25.45]]
  },
  {
    name: "Rio Belém",
    basin: "Bacia do Rio Belém",
    length: 21.0,
    normal: 0.8, alert: 1.8, flood: 2.5, overflow: 3.5,
    course: [[-49.27, -25.38], [-49.27, -25.40], [-49.26, -25.43], [-49.25, -25.46]]
  },
  {
    name: "Rio Atuba",
    basin: "Bacia do Rio Atuba",
    length: 32.0,
    normal: 1.2, alert: 2.8, flood: 4.0, overflow: 5.5,
    course: [[-49.22, -25.35], [-49.23, -25.38], [-49.24, -25.41], [-49.25, -25.44]]
  },
  {
    name: "Rio Passaúna",
    basin: "Bacia do Rio Passaúna",
    length: 48.0,
    normal: 1.0, alert: 2.2, flood: 3.2, overflow: 4.5,
    course: [[-49.38, -25.38], [-49.37, -25.40], [-49.36, -25.43], [-49.35, -25.46]]
  },
]

rivers = rivers_data.map do |data|
  River.find_or_create_by!(name: data[:name]) do |r|
    r.river_basin = basins[data[:basin]]
    r.length_km = data[:length]
    r.normal_level_m = data[:normal]
    r.alert_level_m = data[:alert]
    r.flood_level_m = data[:flood]
    r.overflow_level_m = data[:overflow]
    r.course = line_string(data[:course])
  end
end.index_by(&:name)

# ============================================================
# 5. Sensor Stations (one per basin) + Sensors
# ============================================================
puts "  Creating sensor stations and sensors..."

# Station identifiers match the real CEMADEN idEstacao values returned by
# mapservices.cemaden.gov.br for Curitiba (IBGE 4106902). Coordinates below
# are the real station locations, which the data source APIs use to report
# measurements.
stations_data = [
  {
    eid: "6882", name: "Estação Umbará (bacia Iguaçu)",
    source: "CEMADEN", basin: "Bacia do Rio Iguaçu", river: "Rio Iguaçu",
    neighborhood: "boqueirao", lon: -49.284, lat: -25.555,
    sensors: [
      { type: :river_gauge,  eid: "FLUV-IGUACU-01",  unit: "m",  reading_type: "river_level" },
      { type: :pluviometer,  eid: "PLUV-IGUACU-01",  unit: "mm", reading_type: "precipitation" },
    ]
  },
  {
    eid: "6878", name: "Estação Santa Felicidade (bacia Barigui)",
    source: "CEMADEN", basin: "Bacia do Rio Barigui", river: "Rio Barigui",
    neighborhood: "santa-felicidade", lon: -49.332, lat: -25.382,
    sensors: [
      { type: :river_gauge,  eid: "FLUV-BARIGUI-01", unit: "m",  reading_type: "river_level" },
      { type: :pluviometer,  eid: "PLUV-BARIGUI-01", unit: "mm", reading_type: "precipitation" },
    ]
  },
  {
    eid: "6877", name: "Estação Boa Vista (bacia Belém)",
    source: "CEMADEN", basin: "Bacia do Rio Belém", river: "Rio Belém",
    neighborhood: "boa-vista", lon: -49.245, lat: -25.379,
    sensors: [
      { type: :river_gauge, eid: "FLUV-BELEM-01", unit: "m",  reading_type: "river_level" },
      { type: :pluviometer, eid: "PLUV-BELEM-01", unit: "mm", reading_type: "precipitation" },
    ]
  },
  {
    eid: "6880", name: "Estação Atuba",
    source: "CEMADEN", basin: "Bacia do Rio Atuba", river: "Rio Atuba",
    neighborhood: "cajuru", lon: -49.197, lat: -25.384,
    sensors: [
      { type: :river_gauge,  eid: "FLUV-ATUBA-01",  unit: "m",  reading_type: "river_level" },
      { type: :pluviometer,  eid: "PLUV-ATUBA-01",  unit: "mm", reading_type: "precipitation" },
    ]
  },
  {
    eid: "6873", name: "Estação Butiatuvinha (bacia Passaúna)",
    source: "CEMADEN", basin: "Bacia do Rio Passaúna",
    neighborhood: "cic", lon: -49.36184, lat: -25.41118,
    sensors: [
      { type: :pluviometer,     eid: "PLUV-PASSAUNA-01",  unit: "mm", reading_type: "precipitation" },
      { type: :weather_station, eid: "METEO-PASSAUNA-01", unit: "°C", reading_type: "temperature" },
    ]
  },
  {
    eid: "7297", name: "Estação Novo Mundo (ribeirão Padilhas)",
    source: "CEMADEN", basin: "Bacia do Ribeirão dos Padilhas",
    neighborhood: "sitio-cercado", lon: -49.28797, lat: -25.48784,
    sensors: [
      { type: :pluviometer, eid: "PLUV-PADILHAS-01", unit: "mm", reading_type: "precipitation" },
    ]
  },
]

stations = stations_data.map do |data|
  station = MonitoringStation.find_or_create_by!(external_id: data[:eid]) do |s|
    s.name = data[:name]
    s.data_source = data[:source]
    s.neighborhood = neighborhoods[data[:neighborhood]]
    s.river = rivers[data[:river]] if data[:river]
    s.river_basin = basins[data[:basin]]
    s.location = point(data[:lon], data[:lat])
    s.status = "active"
  end

  data[:sensors].each do |sensor_data|
    Sensor.find_or_create_by!(external_id: sensor_data[:eid]) do |s|
      s.monitoring_station = station
      s.sensor_type = sensor_data[:type]
      s.unit = sensor_data[:unit]
      s.reading_type = sensor_data[:reading_type]
      s.status = "active"
    end
  end

  station
end.index_by { |s| s.external_id }

# ============================================================
# 6. Sample Sensor Readings (last 24 hours)
# ============================================================
puts "  Creating sample sensor readings..."

now = Time.current

Sensor.find_each do |sensor|
  case sensor.sensor_type
  when "river_gauge"
    river = sensor.monitoring_station.river
    next unless river

    base_level = river.normal_level_m
    96.times do |i|
      time = now - (96 - i) * 15.minutes
      # Simulate gradually rising levels
      variation = Math.sin(i * 0.3) * 0.3 + (i > 80 ? (i - 80) * 0.08 : 0)
      value = (base_level + variation).round(2).clamp(0, river.overflow_level_m)

      SensorReading.find_or_create_by!(
        sensor: sensor,
        reading_type: "river_level",
        recorded_at: time
      ) do |r|
        r.value = value
        r.unit = "m"
      end
    end

  when "pluviometer"
    144.times do |i|
      time = now - (144 - i) * 10.minutes
      # Simulate rain event starting ~6 hours ago
      value = if i > 108
                (rand(0.5..8.0) + (i - 108) * 0.2).round(1)
              else
                rand(0.0..1.0).round(1)
              end

      SensorReading.find_or_create_by!(
        sensor: sensor,
        reading_type: "precipitation",
        recorded_at: time
      ) do |r|
        r.value = value
        r.unit = "mm"
      end
    end

  when "weather_station"
    96.times do |i|
      time = now - (96 - i) * 15.minutes
      # Simulate daily temperature curve (cooler at night, warmer midday)
      hour = time.hour + time.min / 60.0
      base_temp = 18.0
      variation = 6.0 * Math.sin((hour - 6) * Math::PI / 12.0)
      value = (base_temp + variation + rand(-0.5..0.5)).round(1)

      SensorReading.find_or_create_by!(
        sensor: sensor,
        reading_type: "temperature",
        recorded_at: time
      ) do |r|
        r.value = value
        r.unit = "°C"
      end
    end
  end
end

# ============================================================
# 7. Alarms (CloudWatch-style, multi-threshold)
# ============================================================
puts "  Creating alarms..."

precip_bands = [
  { severity: 1, value: 20.0 },
  { severity: 2, value: 40.0 },
  { severity: 3, value: 60.0 },
  { severity: 4, value: 80.0 },
]

# One precipitation alarm per basin with 4 threshold bands
precip_alarms = {}
basins.each do |basin_name, basin|
  alarm_name = "Precipitação 3h — #{basin.name}"
  alarm = Alarm.find_by(name: alarm_name)
  unless alarm
    alarm = Alarm.new(
      name: alarm_name,
      alarm_type: "metric",
      enabled: true,
      river_basin: basin,
      metric_name: "precipitation_3h",
      statistic: "Sum",
      period_seconds: 3600,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      missing_data_treatment: "missing",
      state: "insufficient_data"
    )
    precip_bands.each do |band|
      alarm.alarm_thresholds.build(
        severity: band[:severity],
        comparison_operator: "GreaterThanOrEqualToThreshold",
        threshold_value: band[:value],
        unit: "mm"
      )
    end
    alarm.save!
  else
    precip_bands.each do |band|
      AlarmThreshold.find_or_create_by!(alarm: alarm, severity: band[:severity]) do |t|
        t.comparison_operator = "GreaterThanOrEqualToThreshold"
        t.threshold_value = band[:value]
        t.unit = "mm"
      end
    end
  end
  precip_alarms[basin_name] = alarm
end

# One river level alarm per river with 2 threshold bands
river_alarms = {}
rivers.each do |river_name, river|
  alarm_name = "Nível do rio — #{river.name}"
  alarm = Alarm.find_by(name: alarm_name)
  unless alarm
    alarm = Alarm.new(
      name: alarm_name,
      alarm_type: "metric",
      enabled: true,
      river_basin: river.river_basin,
      river: river,
      metric_name: "river_level",
      statistic: "Maximum",
      period_seconds: 300,
      evaluation_periods: 3,
      datapoints_to_alarm: 2,
      missing_data_treatment: "missing",
      state: "insufficient_data"
    )
    [
      { severity: 2, value: river.alert_level_m },
      { severity: 3, value: river.flood_level_m },
    ].each do |band|
      alarm.alarm_thresholds.build(
        severity: band[:severity],
        comparison_operator: "GreaterThanOrEqualToThreshold",
        threshold_value: band[:value],
        unit: "m"
      )
    end
    alarm.save!
  else
    [
      { severity: 2, value: river.alert_level_m },
      { severity: 3, value: river.flood_level_m },
    ].each do |band|
      AlarmThreshold.find_or_create_by!(alarm: alarm, severity: band[:severity]) do |t|
        t.comparison_operator = "GreaterThanOrEqualToThreshold"
        t.threshold_value = band[:value]
        t.unit = "m"
      end
    end
  end
  river_alarms[river_name] = alarm
end

# Alarm actions — severity-aware notifications using min_severity
Alarm.find_each do |alarm|
  next if alarm.alarm_actions.exists?

  # Always notify via websocket
  alarm.alarm_actions.create!(trigger_state: "alarm", action_type: "notification",
                               configuration: { "channels" => %w[websocket] }, enabled: true)
  # SMS at severity 2+
  alarm.alarm_actions.create!(trigger_state: "alarm", action_type: "notification",
                               configuration: { "channels" => %w[sms] }, min_severity: 2, enabled: true)
  # Push at severity 3+
  alarm.alarm_actions.create!(trigger_state: "alarm", action_type: "notification",
                               configuration: { "channels" => %w[push] }, min_severity: 3, enabled: true)
  # Email + civil defense at severity 4
  alarm.alarm_actions.create!(trigger_state: "alarm", action_type: "notification",
                               configuration: { "channels" => %w[email civil_defense] }, min_severity: 4, enabled: true)

  alarm.alarm_actions.create!(trigger_state: "ok", action_type: "notification",
                               configuration: { "channels" => %w[websocket] }, enabled: true)
end

# ============================================================
# 10. Users
# ============================================================
puts "  Creating users..."

[
  { email: "admin@naila.curitiba.pr.gov.br", name: "Administrador NAILA", role: "admin",
    department: "Tecnologia da Informação", phone: "+5541999000001" },
  { email: "coord@defesacivil.curitiba.pr.gov.br", name: "Maria Silva", role: "coordinator",
    department: "Defesa Civil", phone: "+5541999000002" },
  { email: "operador@defesacivil.curitiba.pr.gov.br", name: "João Santos", role: "operator",
    department: "Defesa Civil", phone: "+5541999000003" },
].each do |data|
  User.find_or_create_by!(email_address: data[:email]) do |u|
    u.name = data[:name]
    u.role = data[:role]
    u.department = data[:department]
    u.phone_number = data[:phone]
    u.password = "naila2026"
    u.active = true
    u.receives_sms_alerts = data[:role] != "operator"
  end
end

# ============================================================
# 12. Data Sources
# ============================================================
puts "  Creating data sources..."

[
  { name: "CEMADEN", source_type: "api", base_url: "https://mapservices.cemaden.gov.br", fetch_interval: 600 },
  { name: "OpenWeatherMap", source_type: "api", base_url: "https://api.openweathermap.org", fetch_interval: 1800 },
  { name: "Open-Meteo", source_type: "api", base_url: "https://api.open-meteo.com", fetch_interval: 1800 },
  { name: "IoT Municipal", source_type: "mqtt", base_url: "mqtt://iot.curitiba.pr.gov.br", fetch_interval: 60 },
].each do |data|
  DataSource.find_or_create_by!(name: data[:name]) do |ds|
    ds.source_type = data[:source_type]
    ds.base_url = data[:base_url]
    ds.fetch_interval_seconds = data[:fetch_interval]
    ds.status = "active"
    ds.last_successful_fetch_at = Time.current - rand(60..600).seconds
    ds.consecutive_failures = 0
  end
end

puts "Seeding complete!"
puts "  #{Region.count} regions"
puts "  #{Neighborhood.count} neighborhoods"
puts "  #{RiverBasin.count} river basins"
puts "  #{River.count} rivers"
puts "  #{MonitoringStation.count} sensor stations"
puts "  #{Sensor.count} sensors"
puts "  #{SensorReading.count} sensor readings"
puts "  #{Alarm.count} alarms (#{Alarm.metric_alarms.count} metric)"
puts "  #{AlarmAction.count} alarm actions"
puts "  #{User.count} users"
puts "  #{DataSource.count} data sources"
puts ""
puts "Login: admin@naila.curitiba.pr.gov.br / naila2026"
