import { Controller } from "@hotwired/stimulus"

// Compact vertical bar chart for precipitation readings over time (sidesheet)
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    readings: { type: Array, default: [] }, // [[iso8601, value], ...]
    unit:     { type: String, default: "mm" },
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
    const readings = this.readingsValue
    const unit = this.unitValue

    this.chart.setOption({
      backgroundColor: "transparent",
      tooltip: {
        trigger: "axis",
        backgroundColor: "#1e293b",
        borderColor: "#334155",
        textStyle: { color: "#f1f5f9", fontSize: 11 },
        formatter: (params) => {
          const p = params[0]
          if (!p) return ""
          const date = new Date(p.axisValue)
          const time = date.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })
          return `${time}<br/><strong>${p.value} ${unit}</strong>`
        },
      },
      grid: { top: 8, right: 8, bottom: 24, left: 36 },
      xAxis: {
        type: "time",
        axisLine: { lineStyle: { color: "#334155" } },
        axisLabel: { color: "#94a3b8", fontSize: 9, formatter: "{HH}:{mm}" },
        splitLine: { show: false },
      },
      yAxis: {
        type: "value",
        name: unit,
        nameTextStyle: { color: "#94a3b8", fontSize: 9 },
        axisLine: { show: false },
        axisLabel: { color: "#94a3b8", fontSize: 9 },
        splitLine: { lineStyle: { color: "#334155", type: "dashed" } },
        min: 0,
      },
      series: [{
        type: "bar",
        data: readings.map(([ts, val]) => [ts, val]),
        barMaxWidth: 12,
        itemStyle: {
          borderRadius: [2, 2, 0, 0],
          color: {
            type: "linear",
            x: 0, y: 0, x2: 0, y2: 1,
            colorStops: [
              { offset: 0, color: "#60a5fa" },
              { offset: 1, color: "#3b82f6" },
            ],
          },
        },
      }],
    })
  }

  readingsValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
