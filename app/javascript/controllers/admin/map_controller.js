import { Controller } from "@hotwired/stimulus"

// Risk level → color mapping
const RISK_COLORS = {
  normal:     { fill: "rgba(34, 197, 94, 0.15)",  stroke: "#22c55e", glow: "rgba(34, 197, 94, 0.25)" },
  attention:  { fill: "rgba(234, 179, 8, 0.15)",   stroke: "#eab308", glow: "rgba(234, 179, 8, 0.25)" },
  alert:      { fill: "rgba(249, 115, 22, 0.20)",  stroke: "#f97316", glow: "rgba(249, 115, 22, 0.30)" },
  high_alert: { fill: "rgba(239, 68, 68, 0.25)",   stroke: "#ef4444", glow: "rgba(239, 68, 68, 0.40)" },
  emergency:  { fill: "rgba(168, 85, 247, 0.30)",  stroke: "#a855f7", glow: "rgba(168, 85, 247, 0.50)" },
}

// CartoDB Dark Matter tile URL
const DARK_TILES_URL = "https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    riskZones: { type: Array, default: [] },
    center: { type: Array, default: [-49.2733, -25.4284] },
    zoom: { type: Number, default: 12 },
  }

  async connect() {
    const ol = await import("ol")
    this.ol = ol

    this.initMap()
    this.addRiskZones()
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

    // Risk zone vector layer
    this.riskZoneSource = new ol.source.Vector()
    this.riskZoneLayer = new ol.layer.Vector({
      source: this.riskZoneSource,
      style: (feature) => this.riskZoneStyle(feature),
    })

    // Create map
    this.map = new ol.Map({
      target: this.canvasTarget,
      layers: [this.tileLayer, this.riskZoneLayer],
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
  }

  addRiskZones() {
    const ol = this.ol
    const geojsonFormat = new ol.format.GeoJSON()

    this.riskZonesValue.forEach((zone) => {
      if (!zone.geometry) return

      const feature = geojsonFormat.readFeature(zone.geometry, {
        dataProjection: "EPSG:4326",
        featureProjection: "EPSG:3857",
      })

      feature.set("zoneId", zone.id)
      feature.set("zoneName", zone.name)
      feature.set("riskLevel", zone.risk_level)
      feature.set("zoneType", zone.zone_type)

      this.riskZoneSource.addFeature(feature)
    })

    // Fit view to zones if any exist
    if (this.riskZoneSource.getFeatures().length > 0) {
      this.map.getView().fit(this.riskZoneSource.getExtent(), {
        padding: [40, 40, 40, 40],
        maxZoom: 14,
      })
    }
  }

  riskZoneStyle(feature) {
    const ol = this.ol
    const riskLevel = feature.get("riskLevel") || "normal"
    const colors = RISK_COLORS[riskLevel] || RISK_COLORS.normal

    return new ol.style.Style({
      fill: new ol.style.Fill({ color: colors.fill }),
      stroke: new ol.style.Stroke({
        color: colors.stroke,
        width: 2,
      }),
    })
  }

  handlePointerMove(e) {
    const feature = this.map.forEachFeatureAtPixel(e.pixel, (f) => f)

    if (feature) {
      const name = feature.get("zoneName")
      const riskLevel = feature.get("riskLevel") || "normal"
      const zoneType = feature.get("zoneType") || ""

      const riskLabels = {
        normal: "Normal",
        attention: "Atenção",
        alert: "Alerta",
        high_alert: "Alerta Máximo",
        emergency: "Emergência",
      }

      const typeLabels = {
        flood_plain: "Planície de inundação",
        slope: "Encosta",
        urban_drainage: "Drenagem urbana",
      }

      this.popupEl.innerHTML = `
        <strong>${name}</strong><br>
        Risco: <span style="color: ${(RISK_COLORS[riskLevel] || RISK_COLORS.normal).stroke}">${riskLabels[riskLevel] || riskLevel}</span><br>
        Tipo: ${typeLabels[zoneType] || zoneType}
      `
      this.popupEl.style.display = "block"
      this.popupEl.style.left = `${e.pixel[0] + 12}px`
      this.popupEl.style.top = `${e.pixel[1] - 12}px`

      this.canvasTarget.style.cursor = "pointer"
    } else {
      this.popupEl.style.display = "none"
      this.canvasTarget.style.cursor = ""
    }
  }

  // Called when riskZonesValue changes (Turbo Stream update)
  riskZonesValueChanged() {
    if (!this.map || !this.riskZoneSource) return
    this.riskZoneSource.clear()
    this.addRiskZones()
  }
}
