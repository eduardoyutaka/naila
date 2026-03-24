import { Controller } from "@hotwired/stimulus"

const DARK_TILES_URL = "https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png"
const CURITIBA_CENTER = [-49.2733, -25.4284]

const DRAW_STYLE_FILL   = "rgba(59, 130, 246, 0.15)"
const DRAW_STYLE_STROKE = "#3b82f6"

export default class extends Controller {
  static targets = ["canvas", "input", "status"]
  static values = {
    geometry: { type: String, default: "" },
  }

  connect() {
    this.ol = window.ol
    if (!this.ol) {
      console.error("OpenLayers not loaded")
      return
    }
    this.initMap()
    if (this.geometryValue) {
      this.loadExistingGeometry()
    } else {
      this.addDrawInteraction()
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
      style: new ol.style.Style({
        fill: new ol.style.Fill({ color: DRAW_STYLE_FILL }),
        stroke: new ol.style.Stroke({ color: DRAW_STYLE_STROKE, width: 2 }),
      }),
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
      controls: ol.control.defaults.defaults({ attribution: false }),
    })
  }

  loadExistingGeometry() {
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
      this.addModifyInteraction()
      this.updateStatus("Polígono carregado. Arraste os vértices para editar.")
    } catch (e) {
      console.error("Failed to load existing geometry", e)
      this.addDrawInteraction()
    }
  }

  addDrawInteraction() {
    const ol = this.ol

    // Remove any existing draw interaction
    if (this.drawInteraction) {
      this.map.removeInteraction(this.drawInteraction)
    }

    this.drawInteraction = new ol.interaction.Draw({
      source: this.vectorSource,
      type: "Polygon",
      style: new ol.style.Style({
        fill: new ol.style.Fill({ color: DRAW_STYLE_FILL }),
        stroke: new ol.style.Stroke({ color: DRAW_STYLE_STROKE, width: 2, lineDash: [4, 4] }),
        image: new ol.style.Circle({
          radius: 5,
          fill: new ol.style.Fill({ color: DRAW_STYLE_STROKE }),
        }),
      }),
    })

    this.drawInteraction.on("drawend", (e) => {
      // Only allow one polygon at a time
      this.vectorSource.clear()
      this.vectorSource.addFeature(e.feature)
      this.syncToInput()
      this.map.removeInteraction(this.drawInteraction)
      this.addModifyInteraction()
      this.updateStatus("Polígono desenhado. Arraste os vértices para ajustar.")
    })

    this.map.addInteraction(this.drawInteraction)
    this.updateStatus("Clique no mapa para começar a desenhar o polígono. Clique duplo para finalizar.")
  }

  addModifyInteraction() {
    const ol = this.ol

    if (this.modifyInteraction) {
      this.map.removeInteraction(this.modifyInteraction)
    }

    this.modifyInteraction = new ol.interaction.Modify({
      source: this.vectorSource,
    })

    this.modifyInteraction.on("modifyend", () => {
      this.syncToInput()
    })

    this.map.addInteraction(this.modifyInteraction)
  }

  // Action: called by "Desenhar Polígono" button
  startDraw() {
    if (this.modifyInteraction) {
      this.map.removeInteraction(this.modifyInteraction)
    }
    this.vectorSource.clear()
    if (this.hasInputTarget) this.inputTarget.value = ""
    this.addDrawInteraction()
  }

  // Action: called by "Limpar" button
  clearPolygon() {
    this.vectorSource.clear()
    if (this.hasInputTarget) this.inputTarget.value = ""
    if (this.modifyInteraction) {
      this.map.removeInteraction(this.modifyInteraction)
    }
    this.addDrawInteraction()
    this.updateStatus("")
  }

  syncToInput() {
    if (!this.hasInputTarget) return
    const features = this.vectorSource.getFeatures()
    if (features.length === 0) {
      this.inputTarget.value = ""
      return
    }
    const ol = this.ol
    const geojson = new ol.format.GeoJSON()
    const geometry = features[0].getGeometry().clone().transform("EPSG:3857", "EPSG:4326")
    this.inputTarget.value = geojson.writeGeometry(geometry)
  }

  updateStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }
}
