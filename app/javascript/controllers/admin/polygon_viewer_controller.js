import { Controller } from "@hotwired/stimulus"

const DARK_TILES_URL = "https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png"
const CURITIBA_CENTER = [-49.2733, -25.4284]

const RISK_COLORS = {
  untracked: { fill: "rgba(113, 113, 122, 0.10)", stroke: "rgba(161, 161, 170, 0.55)" },
  normal:     { fill: "rgba(34, 197, 94, 0.15)",  stroke: "#22c55e" },
  attention:  { fill: "rgba(234, 179, 8, 0.15)",   stroke: "#eab308" },
  alert:      { fill: "rgba(249, 115, 22, 0.20)",  stroke: "#f97316" },
  high_alert: { fill: "rgba(239, 68, 68, 0.25)",   stroke: "#ef4444" },
  emergency:  { fill: "rgba(168, 85, 247, 0.30)",  stroke: "#a855f7" },
}

const SEVERITY_TO_RISK = { 1: "attention", 2: "alert", 3: "high_alert", 4: "emergency" }

function basinRiskLevel(monitored, alertSeverity) {
  if (!monitored) return "untracked"
  if (alertSeverity == null || alertSeverity === 0) return "normal"
  return SEVERITY_TO_RISK[alertSeverity] || "normal"
}

export default class extends Controller {
  static targets = ["canvas", "alertSeverities"]
  static values = {
    geometry:       { type: String, default: "" },
    basinId:        { type: Number, default: 0 },
    monitored:      { type: Boolean, default: true },
    alertSeverity:  { type: Number, default: 0 },
  }

  connect() {
    this.ol = window.ol
    if (!this.ol) {
      console.error("OpenLayers not loaded")
      return
    }
    this.initMap()
    if (this.geometryValue) {
      this.loadGeometry()
    }
  }

  disconnect() {
    if (this.map) {
      this.map.setTarget(null)
      this.map = null
    }
  }

  initMap() {
    const ol = this.ol

    this.vectorSource = new ol.source.Vector()
    this.vectorLayer = new ol.layer.Vector({
      source: this.vectorSource,
      style: () => this.polygonStyle(),
    })

    this.map = new ol.Map({
      target: this.canvasTarget,
      layers: [
        new ol.layer.Tile({
          source: new ol.source.XYZ({
            url: DARK_TILES_URL,
            attributions: '&copy; <a href="https://carto.com/">CARTO</a>',
            maxZoom: 19,
          }),
        }),
        this.vectorLayer,
      ],
      view: new ol.View({
        center: ol.proj.fromLonLat(CURITIBA_CENTER),
        zoom: 12,
      }),
      controls: ol.control.defaults.defaults({ attribution: false }).extend([
        new ol.control.ScaleLine({ units: "metric" }),
      ]),
      interactions: ol.interaction.defaults.defaults({ doubleClickZoom: false }),
    })
  }

  loadGeometry() {
    const ol = this.ol
    try {
      const geojson = new ol.format.GeoJSON()
      const geometry = geojson.readGeometry(JSON.parse(this.geometryValue), {
        dataProjection: "EPSG:4326",
        featureProjection: "EPSG:3857",
      })
      const feature = new ol.Feature({ geometry })
      this.vectorSource.addFeature(feature)
      this.map.getView().fit(this.vectorSource.getExtent(), {
        padding: [40, 40, 40, 40],
        maxZoom: 15,
      })
    } catch (e) {
      console.error("Failed to load polygon geometry", e)
    }
  }

  polygonStyle() {
    const ol = this.ol
    const level = basinRiskLevel(this.monitoredValue, this.alertSeverityValue)
    const colors = RISK_COLORS[level] || RISK_COLORS.normal
    return new ol.style.Style({
      fill: new ol.style.Fill({ color: colors.fill }),
      stroke: new ol.style.Stroke({ color: colors.stroke, width: 2 }),
    })
  }

  // Re-renders when the broadcast turbo stream replaces the severities div.
  alertSeveritiesTargetConnected(element) {
    if (!this.vectorLayer) return
    const raw = JSON.parse(element.dataset.value || "{}")
    const severity = raw[this.basinIdValue] ?? raw[String(this.basinIdValue)] ?? 0
    this.alertSeverityValue = severity
    this.vectorLayer.changed()
  }
}
