# frozen_string_literal: true

# Seed data for Naila — Curitiba Flood Risk Monitoring System
# Run with: bin/rails db:seed
#
# This seed creates realistic demo data including Curitiba's administrative
# regions, key neighborhoods, drainage basins, rivers with real threshold
# levels, risk zones, sensor stations, sample readings, alerts, and users.

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
# 3. Drainage Basins
# ============================================================
puts "  Creating drainage basins..."

basins_data = [
  { name: "Bacia do Rio Iguaçu",   area: 308.0 },
  { name: "Bacia do Rio Barigui",   area: 131.0 },
  { name: "Bacia do Rio Belém",     area: 87.8 },
  { name: "Bacia do Rio Atuba",     area: 127.6 },
  { name: "Bacia do Rio Passaúna",  area: 216.0 },
  { name: "Bacia do Rio Ribeirão dos Padilhas", area: 33.0 },
]

basins = basins_data.map do |data|
  DrainageBasin.find_or_create_by!(name: data[:name]) do |b|
    b.area_km2 = data[:area]
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
    r.drainage_basin = basins[data[:basin]]
    r.length_km = data[:length]
    r.normal_level_m = data[:normal]
    r.alert_level_m = data[:alert]
    r.flood_level_m = data[:flood]
    r.overflow_level_m = data[:overflow]
    r.course = line_string(data[:course])
  end
end.index_by(&:name)

# ============================================================
# 5. Risk Zones
# ============================================================
puts "  Creating risk zones..."

risk_zones_data = [
  # Flood plains along rivers
  {
    name: "Planície Rio Iguaçu — Boqueirão",
    type: :flood_plain, neighborhood: "boqueirao",
    basin: "Bacia do Rio Iguaçu", risk: :attention, score: 0.35,
    coords: [[-49.29, -25.47], [-49.27, -25.47], [-49.27, -25.46], [-49.29, -25.46], [-49.29, -25.47]]
  },
  {
    name: "Planície Rio Iguaçu — Ganchinho",
    type: :flood_plain, neighborhood: "ganchinho",
    basin: "Bacia do Rio Iguaçu", risk: :alert, score: 0.52,
    coords: [[-49.28, -25.49], [-49.26, -25.49], [-49.26, -25.48], [-49.28, -25.48], [-49.28, -25.49]]
  },
  {
    name: "Planície Rio Barigui — CIC",
    type: :flood_plain, neighborhood: "cic",
    basin: "Bacia do Rio Barigui", risk: :attention, score: 0.32,
    coords: [[-49.34, -25.43], [-49.32, -25.43], [-49.32, -25.41], [-49.34, -25.41], [-49.34, -25.43]]
  },
  {
    name: "Planície Rio Barigui — Pinheirinho",
    type: :flood_plain, neighborhood: "pinheirinho",
    basin: "Bacia do Rio Barigui", risk: :attention, score: 0.28,
    coords: [[-49.31, -25.45], [-49.29, -25.45], [-49.29, -25.44], [-49.31, -25.44], [-49.31, -25.45]]
  },
  {
    name: "Planície Rio Belém — Centro",
    type: :urban_drainage, neighborhood: "centro",
    basin: "Bacia do Rio Belém", risk: :normal, score: 0.15,
    coords: [[-49.28, -25.43], [-49.26, -25.43], [-49.26, -25.42], [-49.28, -25.42], [-49.28, -25.43]]
  },
  {
    name: "Planície Rio Atuba — Cajuru",
    type: :flood_plain, neighborhood: "cajuru",
    basin: "Bacia do Rio Atuba", risk: :alert, score: 0.48,
    coords: [[-49.24, -25.41], [-49.22, -25.41], [-49.22, -25.39], [-49.24, -25.39], [-49.24, -25.41]]
  },
  {
    name: "Planície Rio Atuba — Atuba",
    type: :flood_plain, neighborhood: "atuba",
    basin: "Bacia do Rio Atuba", risk: :attention, score: 0.35,
    coords: [[-49.23, -25.38], [-49.21, -25.38], [-49.21, -25.37], [-49.23, -25.37], [-49.23, -25.38]]
  },
  # Urban drainage problem areas
  {
    name: "Drenagem Urbana — Rebouças",
    type: :urban_drainage, neighborhood: "reboucas",
    basin: "Bacia do Rio Belém", risk: :attention, score: 0.22,
    coords: [[-49.28, -25.44], [-49.26, -25.44], [-49.26, -25.43], [-49.28, -25.43], [-49.28, -25.44]]
  },
  {
    name: "Drenagem Urbana — Uberaba",
    type: :urban_drainage, neighborhood: "uberaba",
    basin: "Bacia do Rio Iguaçu", risk: :attention, score: 0.25,
    coords: [[-49.25, -25.45], [-49.23, -25.45], [-49.23, -25.44], [-49.25, -25.44], [-49.25, -25.45]]
  },
  {
    name: "Encosta — Tatuquara",
    type: :slope, neighborhood: "tatuquara",
    basin: "Bacia do Rio Ribeirão dos Padilhas", risk: :attention, score: 0.30,
    coords: [[-49.33, -25.50], [-49.31, -25.50], [-49.31, -25.49], [-49.33, -25.49], [-49.33, -25.50]]
  },
  {
    name: "Planície Rio Iguaçu — Sítio Cercado",
    type: :flood_plain, neighborhood: "sitio-cercado",
    basin: "Bacia do Rio Iguaçu", risk: :attention, score: 0.33,
    coords: [[-49.30, -25.50], [-49.28, -25.50], [-49.28, -25.49], [-49.30, -25.49], [-49.30, -25.50]]
  },
]

risk_zones = risk_zones_data.map do |data|
  RiskZone.find_or_create_by!(name: data[:name]) do |z|
    z.zone_type = data[:type]
    z.neighborhood = neighborhoods[data[:neighborhood]]
    z.drainage_basin = basins[data[:basin]]
    z.current_risk_level = data[:risk]
    z.current_risk_score = data[:score]
    z.geometry = polygon(data[:coords])
    z.active = true
  end
end.index_by(&:name)

# ============================================================
# 6. Sensor Stations
# ============================================================
puts "  Creating sensor stations..."

stations_data = [
  # River gauges
  { eid: "RG-IGUACU-01", name: "Rio Iguaçu — Ponte do Guabirotuba", type: :river_gauge,
    source: "SIMEPAR", river: "Rio Iguaçu", basin: "Bacia do Rio Iguaçu",
    neighborhood: "boqueirao", lon: -49.275, lat: -25.465 },
  { eid: "RG-IGUACU-02", name: "Rio Iguaçu — BR-116", type: :river_gauge,
    source: "SIMEPAR", river: "Rio Iguaçu", basin: "Bacia do Rio Iguaçu",
    neighborhood: "uberaba", lon: -49.238, lat: -25.450 },
  { eid: "RG-BARIGUI-01", name: "Rio Barigui — Parque Barigui", type: :river_gauge,
    source: "SIMEPAR", river: "Rio Barigui", basin: "Bacia do Rio Barigui",
    neighborhood: "santa-felicidade", lon: -49.315, lat: -25.400 },
  { eid: "RG-BARIGUI-02", name: "Rio Barigui — CIC", type: :river_gauge,
    source: "SIMEPAR", river: "Rio Barigui", basin: "Bacia do Rio Barigui",
    neighborhood: "cic", lon: -49.330, lat: -25.420 },
  { eid: "RG-BELEM-01", name: "Rio Belém — Centro Cívico", type: :river_gauge,
    source: "SIMEPAR", river: "Rio Belém", basin: "Bacia do Rio Belém",
    neighborhood: "centro-civico", lon: -49.270, lat: -25.405 },
  { eid: "RG-ATUBA-01", name: "Rio Atuba — Cajuru", type: :river_gauge,
    source: "SIMEPAR", river: "Rio Atuba", basin: "Bacia do Rio Atuba",
    neighborhood: "cajuru", lon: -49.230, lat: -25.400 },

  # Pluviometers (CEMADEN + INMET)
  { eid: "PLV-CEMADEN-01", name: "Pluviômetro Centro", type: :pluviometer,
    source: "CEMADEN", neighborhood: "centro", lon: -49.270, lat: -25.429 },
  { eid: "PLV-CEMADEN-02", name: "Pluviômetro Boqueirão", type: :pluviometer,
    source: "CEMADEN", neighborhood: "boqueirao", lon: -49.265, lat: -25.470 },
  { eid: "PLV-CEMADEN-03", name: "Pluviômetro Cajuru", type: :pluviometer,
    source: "CEMADEN", neighborhood: "cajuru", lon: -49.235, lat: -25.405 },
  { eid: "PLV-CEMADEN-04", name: "Pluviômetro CIC", type: :pluviometer,
    source: "CEMADEN", neighborhood: "cic", lon: -49.340, lat: -25.430 },
  { eid: "PLV-INMET-01", name: "Estação INMET Curitiba", type: :pluviometer,
    source: "INMET", neighborhood: "centro", lon: -49.267, lat: -25.433 },
  { eid: "PLV-CEMADEN-05", name: "Pluviômetro Sítio Cercado", type: :pluviometer,
    source: "CEMADEN", neighborhood: "sitio-cercado", lon: -49.290, lat: -25.495 },

  # Weather stations
  { eid: "WS-INMET-CWB", name: "Estação Meteorológica INMET Curitiba", type: :weather_station,
    source: "INMET", neighborhood: "centro", lon: -49.267, lat: -25.433 },
  { eid: "WS-SIMEPAR-01", name: "Estação SIMEPAR Curitiba", type: :weather_station,
    source: "SIMEPAR", neighborhood: "centro-civico", lon: -49.265, lat: -25.400 },
]

stations = stations_data.map do |data|
  SensorStation.find_or_create_by!(external_id: data[:eid]) do |s|
    s.name = data[:name]
    s.station_type = data[:type]
    s.data_source = data[:source]
    s.neighborhood = neighborhoods[data[:neighborhood]]
    s.river = rivers[data[:river]] if data[:river]
    s.drainage_basin = basins[data[:basin]] if data[:basin]
    s.location = point(data[:lon], data[:lat])
    s.status = "active"
  end
end.index_by { |s| s.external_id }

# ============================================================
# 7. Sample Sensor Readings (last 24 hours)
# ============================================================
puts "  Creating sample sensor readings..."

now = Time.current

# River level readings (every 15 min for last 24 hours)
river_stations = stations.values.select(&:station_type_river_gauge?)
river_stations.each do |station|
  river = station.river
  next unless river

  base_level = river.normal_level_m
  96.times do |i|
    time = now - (96 - i) * 15.minutes
    # Simulate gradually rising levels
    variation = Math.sin(i * 0.3) * 0.3 + (i > 80 ? (i - 80) * 0.08 : 0)
    value = (base_level + variation).round(2).clamp(0, river.overflow_level_m)

    SensorReading.find_or_create_by!(
      sensor_station: station,
      reading_type: "river_level",
      recorded_at: time
    ) do |r|
      r.value = value
      r.unit = "m"
    end
  end
end

# Precipitation readings (every 10 min for last 24 hours)
pluvio_stations = stations.values.select(&:station_type_pluviometer?)
pluvio_stations.each do |station|
  144.times do |i|
    time = now - (144 - i) * 10.minutes
    # Simulate rain event starting ~6 hours ago
    value = if i > 108
              (rand(0.5..8.0) + (i - 108) * 0.2).round(1)
            else
              rand(0.0..1.0).round(1)
            end

    SensorReading.find_or_create_by!(
      sensor_station: station,
      reading_type: "precipitation",
      recorded_at: time
    ) do |r|
      r.value = value
      r.unit = "mm"
    end
  end
end

# Temperature readings (every 15 min for last 24 hours)
weather_stations = stations.values.select(&:station_type_weather_station?)
weather_stations.each do |station|
  96.times do |i|
    time = now - (96 - i) * 15.minutes
    # Simulate daily temperature curve (cooler at night, warmer midday)
    hour = time.hour + time.min / 60.0
    base_temp = 18.0
    variation = 6.0 * Math.sin((hour - 6) * Math::PI / 12.0)
    value = (base_temp + variation + rand(-0.5..0.5)).round(1)

    SensorReading.find_or_create_by!(
      sensor_station: station,
      reading_type: "temperature",
      recorded_at: time
    ) do |r|
      r.value = value
      r.unit = "°C"
    end
  end
end

# ============================================================
# 8. Active Alerts
# ============================================================
puts "  Creating sample alerts..."

[
  {
    title: "Nível do Rio Atuba acima do nível de alerta",
    description: "O Rio Atuba na estação Cajuru registrou 3.2m às #{(now - 45.minutes).strftime('%H:%M')}, acima do nível de alerta de 2.8m. Monitoramento intensificado.",
    severity: 2, status: "active", alert_type: "automatic",
    risk_zone: "Planície Rio Atuba — Cajuru",
    neighborhood: "cajuru", river: "Rio Atuba",
    created_at: now - 45.minutes
  },
  {
    title: "Precipitação intensa no Boqueirão",
    description: "Acumulado de 42mm nas últimas 2 horas na região do Boqueirão. Taxa atual de 15mm/h. Risco de alagamento em áreas baixas.",
    severity: 2, status: "active", alert_type: "automatic",
    risk_zone: "Planície Rio Iguaçu — Boqueirão",
    neighborhood: "boqueirao",
    created_at: now - 30.minutes
  },
  {
    title: "Risco elevado de enchente no Ganchinho",
    description: "Combinação de chuva intensa (38mm/2h) e nível do Rio Iguaçu em 4.2m (nível de enchente: 4.5m). Equipes de resposta em prontidão.",
    severity: 3, status: "active", alert_type: "automatic",
    risk_zone: "Planície Rio Iguaçu — Ganchinho",
    neighborhood: "ganchinho", river: "Rio Iguaçu",
    created_at: now - 20.minutes
  },
  {
    title: "Atenção: Solo saturado no Tatuquara",
    description: "Imagens de satélite indicam solo saturado na encosta do Tatuquara. Monitoramento preventivo ativado.",
    severity: 1, status: "active", alert_type: "automatic",
    risk_zone: "Encosta — Tatuquara",
    neighborhood: "tatuquara",
    created_at: now - 2.hours
  },
  {
    title: "Alagamento reportado na Av. Marechal Floriano",
    description: "Defesa Civil registrou alagamento pontual na Av. Marechal Floriano Peixoto, próximo ao Terminal do Boqueirão. Trânsito interrompido.",
    severity: 2, status: "acknowledged", alert_type: "manual",
    neighborhood: "boqueirao",
    created_at: now - 1.hour,
    acknowledged_at: now - 40.minutes
  },
].each do |data|
  Alert.find_or_create_by!(title: data[:title]) do |a|
    a.description = data[:description]
    a.severity = data[:severity]
    a.status = data[:status]
    a.alert_type = data[:alert_type]
    a.risk_zone = risk_zones[data[:risk_zone]] if data[:risk_zone]
    a.neighborhood = neighborhoods[data[:neighborhood]] if data[:neighborhood]
    a.river = rivers[data[:river]] if data[:river]
    a.created_at = data[:created_at]
    a.acknowledged_at = data[:acknowledged_at]
  end
end

# ============================================================
# 9. Alert Thresholds
# ============================================================
puts "  Creating alert thresholds..."

rivers.each_value do |river|
  AlertThreshold.find_or_create_by!(
    river: river,
    parameter: "river_level",
    comparison: "gte",
    severity: 2
  ) do |t|
    t.threshold_type = "river_level_alert"
    t.unit = "m"
    t.value = river.alert_level_m
    t.cooldown_minutes = 60
    t.active = true
  end

  AlertThreshold.find_or_create_by!(
    river: river,
    parameter: "river_level",
    comparison: "gte",
    severity: 3
  ) do |t|
    t.threshold_type = "river_level_flood"
    t.unit = "m"
    t.value = river.flood_level_m
    t.cooldown_minutes = 30
    t.active = true
  end
end

# Precipitation thresholds
[
  { type: "precipitation_strong", param: "precipitation_1h", value: 25.0, severity: 2, cooldown: 60 },
  { type: "precipitation_very_strong", param: "precipitation_1h", value: 50.0, severity: 3, cooldown: 30 },
  { type: "precipitation_extreme", param: "precipitation_1h", value: 80.0, severity: 4, cooldown: 15 },
].each do |data|
  AlertThreshold.find_or_create_by!(threshold_type: data[:type]) do |t|
    t.parameter = data[:param]
    t.comparison = "gte"
    t.value = data[:value]
    t.unit = "mm"
    t.severity = data[:severity]
    t.cooldown_minutes = data[:cooldown]
    t.active = true
  end
end

# ============================================================
# 10. Escalation Rules
# ============================================================
puts "  Creating escalation rules..."

[
  { from: 1, to: 2, after: 120 },
  { from: 2, to: 3, after: 60 },
  { from: 3, to: 4, after: 30 },
].each do |data|
  EscalationRule.find_or_create_by!(from_severity: data[:from], to_severity: data[:to]) do |r|
    r.escalation_after_minutes = data[:after]
    r.active = true
  end
end

# ============================================================
# 11. Users
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
  { name: "INMET", source_type: "api", base_url: "https://apitempo.inmet.gov.br", fetch_interval: 600 },
  { name: "CEMADEN", source_type: "api", base_url: "http://sjc.salvar.cemaden.gov.br", fetch_interval: 600 },
  { name: "SIMEPAR", source_type: "api", base_url: "https://www.simepar.br", fetch_interval: 900 },
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
puts "  #{DrainageBasin.count} drainage basins"
puts "  #{River.count} rivers"
puts "  #{RiskZone.count} risk zones"
puts "  #{SensorStation.count} sensor stations"
puts "  #{SensorReading.count} sensor readings"
puts "  #{Alert.count} alerts"
puts "  #{AlertThreshold.count} alert thresholds"
puts "  #{EscalationRule.count} escalation rules"
puts "  #{User.count} users"
puts "  #{DataSource.count} data sources"
puts ""
puts "Login: admin@naila.curitiba.pr.gov.br / naila2026"
