import { Controller } from "@hotwired/stimulus"
import { CHART_THEME } from "chart_theme"

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

    const t = CHART_THEME
    const accentDark = "#06b6d4"  // cyan — probability line

    this.chart.setOption({
      backgroundColor: t.bg,
      title: {
        text: this.titleValue,
        left: "center",
        textStyle: { color: t.tooltip.text, fontSize: 13, fontWeight: 600 },
      },
      tooltip: {
        trigger: "axis",
        backgroundColor: t.tooltip.bg,
        borderColor: t.tooltip.border,
        textStyle: { color: t.tooltip.text, fontSize: 11 },
        axisPointer: { type: "cross", lineStyle: { color: t.axis.line } },
        formatter(params) {
          let html = `<div style="margin-bottom:4px;color:${t.tooltip.muted};font-size:10px">${params[0].axisValue}</div>`
          params.forEach((p) => {
            const unit = p.seriesName.includes("Probabilidade") ? "%" : " mm"
            html += `<div>${p.marker}${p.seriesName}: <b>${p.value}${unit}</b></div>`
          })
          return html
        },
      },
      legend: {
        bottom: 0,
        textStyle: { color: t.legend.text, fontSize: 10 },
      },
      grid: { top: 44, right: 56, bottom: 72, left: 52 },
      xAxis: {
        type: "category",
        data: times,
        axisLine: { lineStyle: { color: t.axis.line } },
        axisLabel: { color: t.axis.label, fontSize: 10, rotate: 30 },
        splitLine: { show: false },
      },
      yAxis: [
        {
          type: "value",
          name: "mm",
          nameTextStyle: { color: t.axis.label, fontSize: 10 },
          axisLine: { show: false },
          axisLabel: { color: t.axis.label, fontSize: 10 },
          splitLine: { lineStyle: { color: t.axis.split, type: "dashed" } },
        },
        {
          type: "value",
          name: "%",
          min: 0,
          max: 100,
          nameTextStyle: { color: t.axis.label, fontSize: 10 },
          axisLine: { show: false },
          axisLabel: { color: t.axis.label, fontSize: 10, formatter: "{value}%" },
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
                { offset: 0, color: t.accent },
                { offset: 1, color: t.accent + "cc" },
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
          lineStyle: { color: accentDark, width: 1.5 },
          itemStyle: { color: accentDark },
        },
      ],
    })
  }

  forecastsValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
