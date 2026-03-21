import { Controller } from "@hotwired/stimulus"

// Radial gauge for river water levels (current vs thresholds)
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    value:     { type: Number, default: 0 },
    min:       { type: Number, default: 0 },
    max:       { type: Number, default: 10 },
    unit:      { type: String, default: "m" },
    label:     { type: String, default: "" },
    alertAt:   { type: Number, default: 0 },
    floodAt:   { type: Number, default: 0 },
  }

  async connect() {
    const echarts = await import("echarts")
    this.echarts = echarts

    this.chart = echarts.init(this.chartTarget, null, { renderer: "canvas" })
    this.render()

    this.resizeObserver = new ResizeObserver(() => this.chart.resize())
    this.resizeObserver.observe(this.chartTarget)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.chart?.dispose()
  }

  render() {
    const value = this.valueValue
    const min = this.minValue
    const max = this.maxValue
    const alertAt = this.alertAtValue
    const floodAt = this.floodAtValue

    // Build color stops based on thresholds
    const colorStops = []
    if (alertAt > min && alertAt < max) {
      colorStops.push([alertAt / max, "#22c55e"])    // normal → green
      if (floodAt > alertAt && floodAt < max) {
        colorStops.push([floodAt / max, "#eab308"])  // alert → yellow
        colorStops.push([1, "#ef4444"])               // flood → red
      } else {
        colorStops.push([1, "#eab308"])
      }
    } else {
      colorStops.push([0.6, "#22c55e"])
      colorStops.push([0.8, "#eab308"])
      colorStops.push([1, "#ef4444"])
    }

    this.chart.setOption({
      series: [{
        type: "gauge",
        min,
        max,
        splitNumber: 5,
        radius: "90%",
        axisLine: {
          lineStyle: {
            width: 12,
            color: colorStops,
          },
        },
        axisTick: { show: false },
        splitLine: {
          length: 8,
          lineStyle: { color: "#334155", width: 1 },
        },
        axisLabel: {
          distance: 16,
          color: "#94a3b8",
          fontSize: 10,
        },
        pointer: {
          width: 4,
          length: "60%",
          itemStyle: { color: "#f1f5f9" },
        },
        anchor: {
          show: true,
          size: 8,
          itemStyle: { borderColor: "#334155", borderWidth: 2, color: "#1e293b" },
        },
        title: {
          show: true,
          offsetCenter: [0, "70%"],
          color: "#94a3b8",
          fontSize: 11,
        },
        detail: {
          valueAnimation: true,
          formatter: `{value} ${this.unitValue}`,
          offsetCenter: [0, "45%"],
          color: "#f1f5f9",
          fontSize: 18,
          fontWeight: 600,
          fontFamily: "Inter, system-ui, sans-serif",
        },
        data: [{ value, name: this.labelValue }],
      }],
    })
  }

  valueValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
