import { Controller } from "@hotwired/stimulus"

// Risk level → color mapping
const RISK_COLORS = {
  normal:     { fill: "rgba(34, 197, 94, 0.15)",  stroke: "#22c55e", glow: "rgba(34, 197, 94, 0.25)" },
  attention:  { fill: "rgba(234, 179, 8, 0.15)",   stroke: "#eab308", glow: "rgba(234, 179, 8, 0.25)" },
  alert:      { fill: "rgba(249, 115, 22, 0.20)",  stroke: "#f97316", glow: "rgba(249, 115, 22, 0.30)" },
  high_alert: { fill: "rgba(239, 68, 68, 0.25)",   stroke: "#ef4444", glow: "rgba(239, 68, 68, 0.40)" },
  emergency:  { fill: "rgba(168, 85, 247, 0.30)",  stroke: "#a855f7", glow: "rgba(168, 85, 247, 0.50)" },
}

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

export default class extends Controller {
  static targets = ["canvas"]
  static outlets = ["admin--side-sheet"]
  static values = {
    riskZones: { type: Array, default: [] },
    sensors:   { type: Array, default: [] },
    center: { type: Array, default: [-49.2733, -25.4284] },
    zoom: { type: Number, default: 12 },
  }

  async connect() {
    const ol = await import("ol")
    this.ol = ol

    this.initMap()
    this.addRiskZones()
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

    // Risk zone vector layer
    this.riskZoneSource = new ol.source.Vector()
    this.riskZoneLayer = new ol.layer.Vector({
      source: this.riskZoneSource,
      style: (feature) => this.riskZoneStyle(feature),
    })

    // Sensor station vector layer (above risk zones)
    this.sensorSource = new ol.source.Vector()
    this.sensorLayer = new ol.layer.Vector({
      source: this.sensorSource,
      style: (feature) => this.sensorStyle(feature),
      zIndex: 10,
    })

    // Create map
    this.map = new ol.Map({
      target: this.canvasTarget,
      layers: [this.tileLayer, this.riskZoneLayer, this.sensorLayer],
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

  // ── Risk Zones ──

  addRiskZones() {
    const ol = this.ol
    const geojsonFormat = new ol.format.GeoJSON()

    this.riskZonesValue.forEach((zone) => {
      if (!zone.geometry) return

      const feature = geojsonFormat.readFeature(zone.geometry, {
        dataProjection: "EPSG:4326",
        featureProjection: "EPSG:3857",
      })

      feature.set("featureType", "riskZone")
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
      feature.set("stationType", sensor.station_type)
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
    const stationType = feature.get("stationType") || "pluviometer"
    const status = feature.get("status") || "active"

    const fillColor = SENSOR_TYPE_COLORS[stationType] || SENSOR_TYPE_COLORS.pluviometer
    const strokeColor = SENSOR_STATUS_COLORS[status] || SENSOR_STATUS_COLORS.active
    const opacity = status === "inactive" ? 0.4 : 1.0

    const fill = new ol.style.Fill({ color: fillColor + (status === "inactive" ? "66" : "ff") })
    const stroke = new ol.style.Stroke({ color: strokeColor, width: 2 })

    let image
    switch (stationType) {
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
    } else if (featureType === "riskZone") {
      this.showRiskZonePopup(feature, e.pixel)
    } else {
      this.popupEl.style.display = "none"
      this.canvasTarget.style.cursor = ""
      return
    }

    this.canvasTarget.style.cursor = "pointer"
  }

  showRiskZonePopup(feature, pixel) {
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
    this.showPopupAt(pixel)
  }

  showSensorPopup(feature, pixel) {
    const name = feature.get("sensorName")
    const stationType = feature.get("stationType")
    const status = feature.get("status")
    const neighborhood = feature.get("neighborhood")
    const lastValue = feature.get("lastReadingValue")
    const lastAt = feature.get("lastReadingAt")

    const typeLabels = {
      pluviometer: "Pluviômetro",
      river_gauge: "Fluviômetro",
      weather_station: "Estação Meteorológica",
    }

    const statusLabels = {
      active: "Ativo",
      maintenance: "Manutenção",
      inactive: "Inativo",
    }

    const statusColor = SENSOR_STATUS_COLORS[status] || "#22c55e"

    let html = `<strong>${name}</strong><br>
      ${typeLabels[stationType] || stationType} · <span style="color: ${statusColor}">${statusLabels[status] || status}</span>`

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

  // ── Value change callbacks ──

  riskZonesValueChanged() {
    if (!this.map || !this.riskZoneSource) return
    this.riskZoneSource.clear()
    this.addRiskZones()
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
