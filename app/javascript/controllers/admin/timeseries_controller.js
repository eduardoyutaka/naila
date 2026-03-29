import { Controller } from "@hotwired/stimulus"

// Full historical area/line chart with zoom and pan
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    series: { type: Array, default: [] }, // [{ name, data: [[timestamp, value], ...], color }]
    title:  { type: String, default: "" },
    unit:   { type: String, default: "" },
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
    const seriesData = this.seriesValue
    const unit = this.unitValue

    this.chart.setOption({
      backgroundColor: "transparent",
      title: {
        text: this.titleValue,
        left: "center",
        textStyle: { color: "#f1f5f9", fontSize: 13, fontWeight: 600 },
      },
      tooltip: {
        trigger: "axis",
        backgroundColor: "#1e293b",
        borderColor: "#334155",
        textStyle: { color: "#f1f5f9", fontSize: 11 },
        axisPointer: { type: "cross", lineStyle: { color: "#334155" } },
      },
      legend: {
        bottom: 0,
        textStyle: { color: "#94a3b8", fontSize: 10 },
      },
      grid: { top: 40, right: 16, bottom: 64, left: 50 }, 
      xAxis: {
        type: "time",
        axisLine: { lineStyle: { color: "#334155" } },
        axisLabel: { color: "#94a3b8", fontSize: 10 },
        splitLine: { show: false },
      },
      yAxis: {
        type: "value",
        name: unit,
        nameTextStyle: { color: "#94a3b8", fontSize: 10 },
        axisLine: { show: false },
        axisLabel: { color: "#94a3b8", fontSize: 10 },
        splitLine: { lineStyle: { color: "#334155", type: "dashed" } },
      },
      dataZoom: [
        { type: "inside", start: 0, end: 100 },
        {
          type: "slider",
          height: 18,
          bottom: 24,
          borderColor: "#334155",
          backgroundColor: "#111827",
          fillerColor: "rgba(59, 130, 246, 0.15)",
          handleStyle: { color: "#3b82f6" },
          textStyle: { color: "#94a3b8", fontSize: 9 },
        },
      ],
      series: seriesData.map((s) => ({
        name: s.name,
        type: "line",
        data: s.data,
        smooth: true,
        symbol: "none",
        lineStyle: { color: s.color || "#3b82f6", width: 1.5 },
        areaStyle: {
          color: {
            type: "linear",
            x: 0, y: 0, x2: 0, y2: 1,
            colorStops: [
              { offset: 0, color: (s.color || "#3b82f6") + "30" },
              { offset: 1, color: (s.color || "#3b82f6") + "05" },
            ],
          },
        },
      })),
    })
  }

  seriesValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
