import { Controller } from "@hotwired/stimulus"
import { CHART_THEME } from "chart_theme"

// Risk level → color mapping (resolved from CSS custom properties via CHART_THEME)
function buildRiskColors() {
  const s = CHART_THEME.severity
  return {
    normal:     { fill: "rgba(34, 197, 94, 0.15)",  stroke: CHART_THEME.sensor.online,          glow: "rgba(34, 197, 94, 0.25)" },
    attention:  { fill: "rgba(234, 179, 8, 0.15)",   stroke: s[1],                               glow: "rgba(234, 179, 8, 0.25)" },
    alert:      { fill: "rgba(249, 115, 22, 0.20)",  stroke: s[2],                               glow: "rgba(249, 115, 22, 0.30)" },
    high_alert: { fill: "rgba(239, 68, 68, 0.25)",   stroke: s[3],                               glow: "rgba(239, 68, 68, 0.40)" },
    emergency:  { fill: "rgba(168, 85, 247, 0.30)",  stroke: s[4],                               glow: "rgba(168, 85, 247, 0.50)" },
  }
}

// Alert severity (1–4) → risk level name
const SEVERITY_TO_RISK = { 1: "attention", 2: "alert", 3: "high_alert", 4: "emergency" }

// Sensor station type → fill color (from design tokens)
const SENSOR_TYPE_COLORS = {
  pluviometer:     CHART_THEME.sensor.pluviometer,
  river_gauge:     CHART_THEME.sensor.river_gauge,
  weather_station: CHART_THEME.sensor.weather_station,
}

// Sensor status → stroke color (from design tokens)
const SENSOR_STATUS_COLORS = {
  active:      CHART_THEME.sensor.online,
  maintenance: CHART_THEME.sensor.degraded,
  inactive:    CHART_THEME.sensor.offline,
}

// CartoDB Dark Matter tile URL
const DARK_TILES_URL = "https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png"

export default class extends Controller {
  static targets = ["canvas", "alertSeverities"]
  static outlets = ["admin--side-sheet"]
  static values = {
    riverBasins: { type: Array, default: [] },
    sensors:     { type: Array, default: [] },
    center: { type: Array, default: [-49.2733, -25.4284] },
    zoom: { type: Number, default: 12 },
  }

  connect() {
    this.ol = window.ol
    if (!this.ol) {
      console.error("OpenLayers not loaded")
      return
    }

    this.RISK_COLORS = buildRiskColors()
    this.initMap()
    this.addRiverBasins()
    this.addSensors()
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
      layers: [this.tileLayer, this.basinLayer, this.sensorLayer],
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
    this.popupEl.className = "ol-popup rounded-lg border border-white/10 bg-zinc-800 px-3 py-2 text-xs text-white shadow-lg"
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
    const colors = this.RISK_COLORS[riskLevel] || this.RISK_COLORS.normal

    return new ol.style.Style({
      fill: new ol.style.Fill({ color: colors.fill }),
      stroke: new ol.style.Stroke({
        color: colors.stroke,
        width: alertSeverity != null ? 3 : 2,
      }),
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
    const color = (this.RISK_COLORS[riskLevel] || this.RISK_COLORS.normal).stroke

    this.popupEl.textContent = ""

    const strong = document.createElement("strong")
    strong.textContent = name
    this.popupEl.appendChild(strong)
    this.popupEl.appendChild(document.createElement("br"))
    this.popupEl.appendChild(document.createTextNode(`${label}: `))

    const riskSpan = document.createElement("span")
    riskSpan.style.color = color
    riskSpan.textContent = riskLabels[riskLevel] || riskLevel
    this.popupEl.appendChild(riskSpan)

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

    const statusColor = SENSOR_STATUS_COLORS[status] || CHART_THEME.sensor.online
    const typesDisplay = sensorTypes.map(t => typeLabels[t] || t).join(", ")

    this.popupEl.textContent = ""

    const strong = document.createElement("strong")
    strong.textContent = name
    this.popupEl.appendChild(strong)
    this.popupEl.appendChild(document.createElement("br"))

    this.popupEl.appendChild(document.createTextNode(`${typesDisplay || "—"} · `))
    const statusSpan = document.createElement("span")
    statusSpan.style.color = statusColor
    statusSpan.textContent = statusLabels[status] || status
    this.popupEl.appendChild(statusSpan)

    if (neighborhood) {
      this.popupEl.appendChild(document.createElement("br"))
      this.popupEl.appendChild(document.createTextNode(`Bairro: ${neighborhood}`))
    }

    if (lastValue != null && lastAt) {
      const ago = this.timeAgo(new Date(lastAt))
      this.popupEl.appendChild(document.createElement("br"))
      this.popupEl.appendChild(document.createTextNode(`Última leitura: ${lastValue} · ${ago}`))
    }

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

  // ── Value change callbacks ──

  riverBasinsValueChanged() {
    if (!this.map || !this.basinSource) return
    this.basinSource.clear()
    this.addRiverBasins()
  }

  sensorsValueChanged() {
    if (!this.map || !this.sensorSource) return
    this.sensorSource.clear()
    this.addSensors()
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
