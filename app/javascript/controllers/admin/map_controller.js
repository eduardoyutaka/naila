import { Controller } from "@hotwired/stimulus"

// Risk level → color mapping
const RISK_COLORS = {
  normal:     { fill: "rgba(34, 197, 94, 0.15)",  stroke: "#22c55e", glow: "rgba(34, 197, 94, 0.25)" },
  attention:  { fill: "rgba(234, 179, 8, 0.15)",   stroke: "#eab308", glow: "rgba(234, 179, 8, 0.25)" },
  alert:      { fill: "rgba(249, 115, 22, 0.20)",  stroke: "#f97316", glow: "rgba(249, 115, 22, 0.30)" },
  high_alert: { fill: "rgba(239, 68, 68, 0.25)",   stroke: "#ef4444", glow: "rgba(239, 68, 68, 0.40)" },
  emergency:  { fill: "rgba(168, 85, 247, 0.30)",  stroke: "#a855f7", glow: "rgba(168, 85, 247, 0.50)" },
}

// Alert severity (1–4) → risk level name
const SEVERITY_TO_RISK = { 1: "attention", 2: "alert", 3: "high_alert", 4: "emergency" }

// Sensor station type → fill color
const SENSOR_TYPE_COLORS = {
  pluviometer:     "#3b82f6",
  river_gauge:     "#06b6d4",
  weather_station: "#8b5cf6",
}

// Sensor status → stroke color
const SENSOR_STATUS_COLORS = {
  active:      "#22c55e",
  maintenance: "#eab308",
  inactive:    "#ef4444",
}

// CartoDB Dark Matter tile URL
const DARK_TILES_URL = "https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png"

// WMO weather code → icon + pt-BR label
const WMO_WEATHER = {
  0:  { icon: "\u2600\uFE0F", label: "Céu limpo" },
  1:  { icon: "\uD83C\uDF24\uFE0F", label: "Predom. limpo" },
  2:  { icon: "\u26C5", label: "Parcialmente nublado" },
  3:  { icon: "\u2601\uFE0F", label: "Nublado" },
  45: { icon: "\uD83C\uDF2B\uFE0F", label: "Nevoeiro" },
  48: { icon: "\uD83C\uDF2B\uFE0F", label: "Nevoeiro com geada" },
  51: { icon: "\uD83C\uDF26\uFE0F", label: "Garoa leve" },
  53: { icon: "\uD83C\uDF26\uFE0F", label: "Garoa moderada" },
  55: { icon: "\uD83C\uDF27\uFE0F", label: "Garoa intensa" },
  56: { icon: "\uD83C\uDF27\uFE0F", label: "Garoa congelante" },
  57: { icon: "\uD83C\uDF27\uFE0F", label: "Garoa congelante forte" },
  61: { icon: "\uD83C\uDF27\uFE0F", label: "Chuva leve" },
  63: { icon: "\uD83C\uDF27\uFE0F", label: "Chuva moderada" },
  65: { icon: "\uD83C\uDF27\uFE0F", label: "Chuva forte" },
  66: { icon: "\uD83C\uDF27\uFE0F", label: "Chuva congelante" },
  67: { icon: "\uD83C\uDF27\uFE0F", label: "Chuva congelante forte" },
  71: { icon: "\uD83C\uDF28\uFE0F", label: "Neve leve" },
  73: { icon: "\uD83C\uDF28\uFE0F", label: "Neve moderada" },
  75: { icon: "\u2744\uFE0F",  label: "Neve forte" },
  77: { icon: "\u2744\uFE0F",  label: "Granizo" },
  80: { icon: "\uD83C\uDF27\uFE0F", label: "Pancada leve" },
  81: { icon: "\uD83C\uDF27\uFE0F", label: "Pancada moderada" },
  82: { icon: "\uD83C\uDF27\uFE0F", label: "Pancada forte" },
  95: { icon: "\u26C8\uFE0F", label: "Trovoada" },
  96: { icon: "\u26C8\uFE0F", label: "Trovoada com granizo" },
  99: { icon: "\u26C8\uFE0F", label: "Trovoada com granizo forte" },
}

// Precipitation mm → blue overlay opacity for basin wash
const PRECIP_OPACITY = [
  { threshold: 15,  opacity: 0.35 },
  { threshold: 7.5, opacity: 0.25 },
  { threshold: 2.5, opacity: 0.15 },
  { threshold: 0.5, opacity: 0.08 },
]

function precipToOpacity(mm) {
  for (const { threshold, opacity } of PRECIP_OPACITY) {
    if (mm >= threshold) return opacity
  }
  return 0.0
}

export default class extends Controller {
  static targets = ["canvas", "alertSeverities", "forecastTimelineUpdate"]
  static outlets = ["admin--side-sheet"]
  static values = {
    riverBasins:      { type: Array, default: [] },
    sensors:          { type: Array, default: [] },
    forecastTimeline: { type: Array, default: [] },
    currentWeather:   { type: Object, default: {} },
    center: { type: Array, default: [-49.2733, -25.4284] },
    zoom: { type: Number, default: 12 },
  }

  connect() {
    this.ol = window.ol
    if (!this.ol) {
      console.error("OpenLayers not loaded")
      return
    }

    this.forecastIndex = 0

    this.initMap()
    this.addRiverBasins()
    this.addPrecipOverlay()
    this.addSensors()
    this.initWeatherOverlay()
  }

  disconnect() {
    if (this.map) {
      this.map.setTarget(null)
      this.map = null
    }
  }

  initMap() {
    const ol = this.ol

    // Dark tile layer
    this.tileLayer = new ol.layer.Tile({
      source: new ol.source.XYZ({
        url: DARK_TILES_URL,
        attributions: '&copy; <a href="https://carto.com/">CARTO</a>',
        maxZoom: 19,
      }),
    })

    // River basin vector layer
    this.basinSource = new ol.source.Vector()
    this.basinLayer = new ol.layer.Vector({
      source: this.basinSource,
      style: (feature) => this.basinStyle(feature),
    })

    // Precipitation overlay layer (between basins and sensors)
    this.precipSource = new ol.source.Vector()
    this.precipLayer = new ol.layer.Vector({
      source: this.precipSource,
      zIndex: 5,
    })

    // Sensor station vector layer (above basins)
    this.sensorSource = new ol.source.Vector()
    this.sensorLayer = new ol.layer.Vector({
      source: this.sensorSource,
      style: (feature) => this.sensorStyle(feature),
      zIndex: 10,
    })

    // Create map
    this.map = new ol.Map({
      target: this.canvasTarget,
      layers: [this.tileLayer, this.basinLayer, this.precipLayer, this.sensorLayer],
      view: new ol.View({
        center: ol.proj.fromLonLat(this.centerValue),
        zoom: this.zoomValue,
      }),
      controls: ol.control.defaults.defaults({ attribution: false }).extend([
        new ol.control.Attribution({ collapsible: true }),
        new ol.control.ScaleLine({ units: "metric" }),
      ]),
    })

    // Popup overlay for hover
    this.popupEl = document.createElement("div")
    this.popupEl.className = "ol-popup rounded-lg border border-naila-border bg-naila-elevated px-3 py-2 text-xs text-naila-text shadow-lg"
    this.popupEl.style.cssText = "position: absolute; pointer-events: none; white-space: nowrap; display: none;"
    this.canvasTarget.appendChild(this.popupEl)

    this.map.on("pointermove", (e) => this.handlePointerMove(e))
    this.map.on("click", (e) => this.handleClick(e))
  }

  // ── River Basins ──

  addRiverBasins() {
    const ol = this.ol
    const geojsonFormat = new ol.format.GeoJSON()

    this.riverBasinsValue.forEach((basin) => {
      if (!basin.geometry) return

      const feature = geojsonFormat.readFeature(basin.geometry, {
        dataProjection: "EPSG:4326",
        featureProjection: "EPSG:3857",
      })

      feature.set("featureType", "riverBasin")
      feature.set("basinId", basin.id)
      feature.set("basinName", basin.name)
      feature.set("riskLevel", basin.risk_level)
      feature.set("alertSeverity", basin.alert_severity ?? null)

      this.basinSource.addFeature(feature)
    })

    // Fit view to basins if any exist
    if (this.basinSource.getFeatures().length > 0) {
      this.map.getView().fit(this.basinSource.getExtent(), {
        padding: [40, 40, 40, 40],
        maxZoom: 14,
      })
    }
  }

  basinStyle(feature) {
    const ol = this.ol
    const alertSeverity = feature.get("alertSeverity")
    const riskLevel = alertSeverity != null
      ? (SEVERITY_TO_RISK[alertSeverity] || "normal")
      : (feature.get("riskLevel") || "normal")
    const colors = RISK_COLORS[riskLevel] || RISK_COLORS.normal

    return new ol.style.Style({
      fill: new ol.style.Fill({ color: colors.fill }),
      stroke: new ol.style.Stroke({
        color: colors.stroke,
        width: alertSeverity != null ? 3 : 2,
      }),
    })
  }

  // ── Precipitation Overlay ──

  addPrecipOverlay() {
    this.updatePrecipOverlay()
  }

  updatePrecipOverlay() {
    const ol = this.ol
    this.precipSource.clear()

    const timeline = this.forecastTimelineValue
    if (!timeline.length) return

    const forecast = timeline[this.forecastIndex]
    if (!forecast) return

    const opacity = precipToOpacity(forecast.precipitation_mm)
    if (opacity === 0) return

    const fillColor = `rgba(59, 130, 246, ${opacity})`
    const style = new ol.style.Style({
      fill: new ol.style.Fill({ color: fillColor }),
      stroke: new ol.style.Stroke({ color: `rgba(59, 130, 246, ${Math.min(opacity + 0.1, 0.5)})`, width: 1 }),
    })

    this.basinSource.getFeatures().forEach((feature) => {
      if (feature.get("featureType") !== "riverBasin") return
      const clone = feature.clone()
      clone.set("featureType", "precipOverlay")
      clone.setStyle(style)
      this.precipSource.addFeature(clone)
    })
  }

  // ── Sensors ──

  addSensors() {
    const ol = this.ol

    this.sensorsValue.forEach((sensor) => {
      if (!sensor.lat || !sensor.lng) return

      const coords = ol.proj.fromLonLat([sensor.lng, sensor.lat])
      const feature = new ol.Feature({ geometry: new ol.geom.Point(coords) })

      feature.set("featureType", "sensor")
      feature.set("sensorId", sensor.id)
      feature.set("sensorName", sensor.name)
      feature.set("sensorTypes", sensor.sensor_types || [])
      feature.set("status", sensor.status)
      feature.set("neighborhood", sensor.neighborhood)
      feature.set("river", sensor.river)
      feature.set("lastReadingValue", sensor.last_reading_value)
      feature.set("lastReadingAt", sensor.last_reading_at)

      this.sensorSource.addFeature(feature)
    })
  }

  sensorStyle(feature) {
    const ol = this.ol
    const sensorTypes = feature.get("sensorTypes") || []
    // Use primary type for styling (river_gauge > weather_station > pluviometer)
    const primaryType = sensorTypes.includes("river_gauge") ? "river_gauge"
                      : sensorTypes.includes("weather_station") ? "weather_station"
                      : "pluviometer"
    const status = feature.get("status") || "active"

    const fillColor = SENSOR_TYPE_COLORS[primaryType] || SENSOR_TYPE_COLORS.pluviometer
    const strokeColor = SENSOR_STATUS_COLORS[status] || SENSOR_STATUS_COLORS.active

    const fill = new ol.style.Fill({ color: fillColor + (status === "inactive" ? "66" : "ff") })
    const stroke = new ol.style.Stroke({ color: strokeColor, width: 2 })

    let image
    switch (primaryType) {
      case "river_gauge":
        image = new ol.style.Circle({ radius: 7, fill, stroke })
        break
      case "weather_station":
        image = new ol.style.RegularShape({ points: 4, radius: 8, angle: Math.PI / 4, fill, stroke })
        break
      default: // pluviometer — square
        image = new ol.style.RegularShape({ points: 4, radius: 7, angle: 0, fill, stroke })
        break
    }

    return new ol.style.Style({ image })
  }

  // ── Weather Overlay ──

  initWeatherOverlay() {
    const timeline = this.forecastTimelineValue
    if (!timeline.length && !this.currentWeatherValue.temperature_c) return

    this.overlayEl = document.createElement("div")
    this.overlayEl.className = "weather-overlay rounded-lg border border-naila-border bg-naila-elevated/95 px-3 py-2.5 text-xs text-naila-text shadow-lg backdrop-blur-sm"
    this.overlayEl.innerHTML = this.buildOverlayHTML()
    this.canvasTarget.appendChild(this.overlayEl)

    this.overlayEl.addEventListener("click", (e) => this.handleOverlayClick(e))
  }

  buildOverlayHTML() {
    const timeline = this.forecastTimelineValue
    const current = this.currentWeatherValue

    if (!timeline.length) {
      const temp = current.temperature_c != null ? `${current.temperature_c}\u00B0C` : "--"
      const condition = current.weather_condition || "Sem dados"
      return `
        <div class="flex items-center gap-2 mb-1">
          <span class="text-base">\uD83C\uDF27\uFE0F</span>
          <span class="font-medium text-naila-text">${condition}</span>
        </div>
        <div class="text-naila-text-muted">${temp}</div>
        <div class="mt-1.5 text-[10px] text-naila-text-muted">Sem previs\u00E3o dispon\u00EDvel</div>
      `
    }

    const forecast = timeline[this.forecastIndex] || timeline[0]
    const wmo = WMO_WEATHER[forecast.weather_code] || WMO_WEATHER[0]
    const from = new Date(forecast.valid_from)
    const until = new Date(forecast.valid_until)

    const timeLabel = this.formatTimeRange(from, until)
    const tempRange = forecast.temperature_min_c != null && forecast.temperature_max_c != null
      ? `${forecast.temperature_min_c}\u00B0 / ${forecast.temperature_max_c}\u00B0C`
      : "--"

    // Step dots
    const maxDots = Math.min(timeline.length, 8)
    const step = timeline.length <= maxDots ? 1 : Math.ceil(timeline.length / maxDots)
    let dots = ""
    for (let i = 0; i < timeline.length; i += step) {
      const active = Math.abs(i - this.forecastIndex) < step ? "active" : ""
      dots += `<span class="weather-overlay-step ${active}" data-step="${i}"></span>`
    }

    return `
      <div class="flex items-center gap-2 mb-1">
        <span class="text-base">${wmo.icon}</span>
        <span class="font-medium text-naila-text">${wmo.label}</span>
      </div>
      <div class="flex items-center gap-3 text-naila-text-muted">
        <span>${tempRange}</span>
        <span class="text-[#3b82f6]">\uD83D\uDCA7 ${forecast.precipitation_mm} mm</span>
        <span>${forecast.precipitation_probability}%</span>
      </div>
      <div class="mt-1.5 flex items-center gap-1.5">
        <button data-action="prev" class="text-naila-text-muted hover:text-naila-text transition-colors text-sm leading-none">\u25C0</button>
        <div class="flex items-center gap-1">${dots}</div>
        <button data-action="next" class="text-naila-text-muted hover:text-naila-text transition-colors text-sm leading-none">\u25B6</button>
        <span class="ml-1 text-[10px] text-naila-text-muted tabular-nums">${timeLabel}</span>
      </div>
    `
  }

  handleOverlayClick(e) {
    const target = e.target
    const timeline = this.forecastTimelineValue
    if (!timeline.length) return

    if (target.dataset.action === "prev") {
      this.forecastIndex = Math.max(0, this.forecastIndex - 1)
      this.refreshWeatherOverlay()
    } else if (target.dataset.action === "next") {
      this.forecastIndex = Math.min(timeline.length - 1, this.forecastIndex + 1)
      this.refreshWeatherOverlay()
    } else if (target.dataset.step != null) {
      this.forecastIndex = parseInt(target.dataset.step, 10)
      this.refreshWeatherOverlay()
    }
  }

  refreshWeatherOverlay() {
    if (this.overlayEl) {
      this.overlayEl.innerHTML = this.buildOverlayHTML()
    }
    this.updatePrecipOverlay()
  }

  formatTimeRange(from, until) {
    const opts = { hour: "2-digit", minute: "2-digit", hour12: false, timeZone: "America/Sao_Paulo" }
    const dayOpts = { weekday: "short", timeZone: "America/Sao_Paulo" }

    const now = new Date()
    const today = now.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit", timeZone: "America/Sao_Paulo" })
    const fromDay = from.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit", timeZone: "America/Sao_Paulo" })

    const dayLabel = fromDay === today ? "Hoje" : from.toLocaleDateString("pt-BR", dayOpts)
    const fromTime = from.toLocaleTimeString("pt-BR", opts)
    const untilTime = until.toLocaleTimeString("pt-BR", opts)

    return `${dayLabel} ${fromTime}\u2013${untilTime}`
  }

  // ── Interactions ──

  handlePointerMove(e) {
    const feature = this.map.forEachFeatureAtPixel(e.pixel, (f) => f)

    if (!feature) {
      this.popupEl.style.display = "none"
      this.canvasTarget.style.cursor = ""
      return
    }

    const featureType = feature.get("featureType")

    if (featureType === "sensor") {
      this.showSensorPopup(feature, e.pixel)
    } else if (featureType === "riverBasin") {
      this.showBasinPopup(feature, e.pixel)
    } else {
      this.popupEl.style.display = "none"
      this.canvasTarget.style.cursor = ""
      return
    }

    this.canvasTarget.style.cursor = "pointer"
  }

  showBasinPopup(feature, pixel) {
    const name = feature.get("basinName")
    const alertSeverity = feature.get("alertSeverity")
    const riskLevel = alertSeverity != null
      ? (SEVERITY_TO_RISK[alertSeverity] || "normal")
      : (feature.get("riskLevel") || "normal")

    const riskLabels = {
      normal: "Normal",
      attention: "Atenção",
      alert: "Alerta",
      high_alert: "Alerta Máximo",
      emergency: "Emergência",
    }

    const label = alertSeverity != null ? "Alerta" : "Risco"
    const color = (RISK_COLORS[riskLevel] || RISK_COLORS.normal).stroke

    let html = `
      <strong>${name}</strong><br>
      ${label}: <span style="color: ${color}">${riskLabels[riskLevel] || riskLevel}</span>
    `

    // Append forecast precipitation if available
    const timeline = this.forecastTimelineValue
    if (timeline.length > 0) {
      const forecast = timeline[this.forecastIndex]
      if (forecast) {
        const wmo = WMO_WEATHER[forecast.weather_code] || WMO_WEATHER[0]
        html += `<br><span style="color: #94a3b8">${wmo.icon} ${forecast.precipitation_mm} mm \u00B7 ${forecast.precipitation_probability}% prob.</span>`
      }
    }

    this.popupEl.innerHTML = html
    this.showPopupAt(pixel)
  }

  showSensorPopup(feature, pixel) {
    const name = feature.get("sensorName")
    const sensorTypes = feature.get("sensorTypes") || []
    const status = feature.get("status")
    const neighborhood = feature.get("neighborhood")
    const lastValue = feature.get("lastReadingValue")
    const lastAt = feature.get("lastReadingAt")

    const typeLabels = {
      pluviometer: "Pluviômetro",
      river_gauge: "Fluviômetro",
      weather_station: "Meteorológica",
    }

    const statusLabels = {
      active: "Ativo",
      maintenance: "Manutenção",
      inactive: "Inativo",
    }

    const statusColor = SENSOR_STATUS_COLORS[status] || "#22c55e"
    const typesDisplay = sensorTypes.map(t => typeLabels[t] || t).join(", ")

    let html = `<strong>${name}</strong><br>
      ${typesDisplay || "—"} · <span style="color: ${statusColor}">${statusLabels[status] || status}</span>`

    if (neighborhood) {
      html += `<br>Bairro: ${neighborhood}`
    }

    if (lastValue != null && lastAt) {
      const ago = this.timeAgo(new Date(lastAt))
      html += `<br>Última leitura: ${lastValue} · ${ago}`
    }

    this.popupEl.innerHTML = html
    this.showPopupAt(pixel)
  }

  showPopupAt(pixel) {
    this.popupEl.style.display = "block"
    this.popupEl.style.left = `${pixel[0] + 12}px`
    this.popupEl.style.top = `${pixel[1] - 12}px`
  }

  handleClick(e) {
    const feature = this.map.forEachFeatureAtPixel(e.pixel, (f) => f)

    if (feature && feature.get("featureType") === "sensor") {
      const sensorId = feature.get("sensorId")
      if (this.hasAdminSideSheetOutlet) {
        this.adminSideSheetOutlet.open(sensorId)
      }
    }
  }

  // ── Target callbacks ──

  alertSeveritiesTargetConnected(element) {
    // Skip during initial connect() — alert_severity is already embedded in riverBasinsValue
    if (!this.basinSource) return
    const raw = JSON.parse(element.dataset.value || "{}")
    // Normalize string keys from JSON to integers matching basinId
    const severities = Object.fromEntries(Object.entries(raw).map(([k, v]) => [parseInt(k, 10), v]))
    this.basinSource.getFeatures().forEach((feature) => {
      if (feature.get("featureType") !== "riverBasin") return
      const severity = severities[feature.get("basinId")] ?? null
      feature.set("alertSeverity", severity)
    })
    this.basinLayer.changed()
  }

  forecastTimelineUpdateTargetConnected(element) {
    if (!this.map) return
    const timeline = JSON.parse(element.dataset.value || "[]")
    this.forecastTimelineValue = timeline
    this.forecastIndex = Math.min(this.forecastIndex, Math.max(0, timeline.length - 1))
    this.refreshWeatherOverlay()
  }

  // ── Value change callbacks ──

  riverBasinsValueChanged() {
    if (!this.map || !this.basinSource) return
    this.basinSource.clear()
    this.addRiverBasins()
    this.updatePrecipOverlay()
  }

  sensorsValueChanged() {
    if (!this.map || !this.sensorSource) return
    this.sensorSource.clear()
    this.addSensors()
  }

  forecastTimelineValueChanged() {
    if (!this.map) return
    this.refreshWeatherOverlay()
  }

  // ── Helpers ──

  timeAgo(date) {
    const seconds = Math.floor((new Date() - date) / 1000)
    if (seconds < 60) return "agora"
    const minutes = Math.floor(seconds / 60)
    if (minutes < 60) return `${minutes}min atrás`
    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours}h atrás`
    const days = Math.floor(hours / 24)
    return `${days}d atrás`
  }
}
