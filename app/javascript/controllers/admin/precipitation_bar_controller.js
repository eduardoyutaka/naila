import { Controller } from "@hotwired/stimulus"

// Horizontal bar chart for accumulated rainfall by neighborhood
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    data:  { type: Array, default: [] }, // [{ name, value }, ...]
    title: { type: String, default: "" },
    unit:  { type: String, default: "mm" },
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
    const items = this.dataValue.sort((a, b) => b.value - a.value)
    const names = items.map((d) => d.name)
    const values = items.map((d) => d.value)
    const unit = this.unitValue

    this.chart.setOption({
      backgroundColor: "transparent",
      title: {
        text: this.titleValue,
        left: "center",
        textStyle: { color: "#f1f5f9", fontSize: 13, fontWeight: 600 },
      },
      tooltip: {
        backgroundColor: "#1e293b",
        borderColor: "#334155",
        textStyle: { color: "#f1f5f9", fontSize: 11 },
        formatter: (params) => `${params.name}: <strong>${params.value} ${unit}</strong>`,
      },
      grid: { top: 36, right: 16, bottom: 8, left: 100 },
      xAxis: {
        type: "value",
        axisLine: { lineStyle: { color: "#334155" } },
        axisLabel: { color: "#94a3b8", fontSize: 10 },
        splitLine: { lineStyle: { color: "#334155", type: "dashed" } },
      },
      yAxis: {
        type: "category",
        data: names,
        inverse: true,
        axisLine: { lineStyle: { color: "#334155" } },
        axisLabel: { color: "#94a3b8", fontSize: 10, width: 90, overflow: "truncate" },
      },
      series: [{
        type: "bar",
        data: values,
        barMaxWidth: 16,
        itemStyle: {
          borderRadius: [0, 4, 4, 0],
          color: {
            type: "linear",
            x: 0, y: 0, x2: 1, y2: 0,
            colorStops: [
              { offset: 0, color: "#3b82f6" },
              { offset: 1, color: "#60a5fa" },
            ],
          },
        },
      }],
    })
  }

  dataValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
