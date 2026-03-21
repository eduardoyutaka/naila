import { Controller } from "@hotwired/stimulus"

// Mini inline line chart for trends (e.g., precipitation last 24h)
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    data:  { type: Array, default: [] },
    color: { type: String, default: "#3b82f6" },
    label: { type: String, default: "" },
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
    const data = this.dataValue
    const color = this.colorValue

    this.chart.setOption({
      grid: { top: 4, right: 4, bottom: 4, left: 4 },
      xAxis: {
        type: "category",
        show: false,
        data: data.map((_, i) => i),
      },
      yAxis: {
        type: "value",
        show: false,
      },
      series: [{
        type: "line",
        data,
        smooth: true,
        symbol: "none",
        lineStyle: { color, width: 1.5 },
        areaStyle: {
          color: {
            type: "linear",
            x: 0, y: 0, x2: 0, y2: 1,
            colorStops: [
              { offset: 0, color: color + "40" },
              { offset: 1, color: color + "05" },
            ],
          },
        },
      }],
      tooltip: {
        trigger: "axis",
        backgroundColor: "#1e293b",
        borderColor: "#334155",
        textStyle: { color: "#f1f5f9", fontSize: 11 },
        formatter: (params) => {
          const val = params[0]?.value ?? "—"
          return `${this.labelValue ? this.labelValue + ": " : ""}${val}`
        },
      },
    })
  }

  dataValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
