import { Controller } from "@hotwired/stimulus"

// Dual y-axis ECharts chart for precipitation forecast (bars) + probability (line)
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    forecasts: { type: Array, default: [] }, // [{ time, precipitation_mm, probability }]
    title: { type: String, default: "" },
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
    const forecasts = this.forecastsValue
    const times = forecasts.map((f) => f.time)
    const precipData = forecasts.map((f) => f.precipitation_mm)
    const probData = forecasts.map((f) => f.probability)

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
        formatter(params) {
          let html = `<div style="margin-bottom:4px;color:#94a3b8;font-size:10px">${params[0].axisValue}</div>`
          params.forEach((p) => {
            const unit = p.seriesName.includes("Probabilidade") ? "%" : " mm"
            html += `<div>${p.marker}${p.seriesName}: <b>${p.value}${unit}</b></div>`
          })
          return html
        },
      },
      legend: {
        bottom: 0,
        textStyle: { color: "#94a3b8", fontSize: 10 },
      },
      grid: { top: 44, right: 56, bottom: 72, left: 52 },
      xAxis: {
        type: "category",
        data: times,
        axisLine: { lineStyle: { color: "#334155" } },
        axisLabel: { color: "#94a3b8", fontSize: 10, rotate: 30 },
        splitLine: { show: false },
      },
      yAxis: [
        {
          type: "value",
          name: "mm",
          nameTextStyle: { color: "#94a3b8", fontSize: 10 },
          axisLine: { show: false },
          axisLabel: { color: "#94a3b8", fontSize: 10 },
          splitLine: { lineStyle: { color: "#334155", type: "dashed" } },
        },
        {
          type: "value",
          name: "%",
          min: 0,
          max: 100,
          nameTextStyle: { color: "#94a3b8", fontSize: 10 },
          axisLine: { show: false },
          axisLabel: { color: "#94a3b8", fontSize: 10, formatter: "{value}%" },
          splitLine: { show: false },
        },
      ],
      series: [
        {
          name: "Precipitação",
          type: "bar",
          yAxisIndex: 0,
          data: precipData,
          itemStyle: {
            color: {
              type: "linear",
              x: 0, y: 0, x2: 0, y2: 1,
              colorStops: [
                { offset: 0, color: "#3b82f6" },
                { offset: 1, color: "#1d4ed8" },
              ],
            },
            borderRadius: [3, 3, 0, 0],
          },
        },
        {
          name: "Probabilidade",
          type: "line",
          yAxisIndex: 1,
          data: probData,
          smooth: true,
          symbol: "circle",
          symbolSize: 4,
          lineStyle: { color: "#06b6d4", width: 1.5 },
          itemStyle: { color: "#06b6d4" },
        },
      ],
    })
  }

  forecastsValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
