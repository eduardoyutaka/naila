import { Controller } from "@hotwired/stimulus"
import { CHART_THEME, resolveColor } from "chart_theme"

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

    const t = CHART_THEME

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
      },
      legend: {
        bottom: 0,
        textStyle: { color: t.legend.text, fontSize: 10 },
      },
      grid: { top: 40, right: 16, bottom: 64, left: 50 },
      xAxis: {
        type: "time",
        axisLine: { lineStyle: { color: t.axis.line } },
        axisLabel: { color: t.axis.label, fontSize: 10 },
        splitLine: { show: false },
      },
      yAxis: {
        type: "value",
        name: unit,
        nameTextStyle: { color: t.axis.label, fontSize: 10 },
        axisLine: { show: false },
        axisLabel: { color: t.axis.label, fontSize: 10 },
        splitLine: { lineStyle: { color: t.axis.split, type: "dashed" } },
      },
      dataZoom: [
        { type: "inside", start: 0, end: 100 },
        {
          type: "slider",
          height: 18,
          bottom: 24,
          borderColor: t.dataZoom.border,
          backgroundColor: t.dataZoom.bg,
          fillerColor: t.dataZoom.filler,
          handleStyle: { color: t.dataZoom.handle },
          textStyle: { color: t.axis.label, fontSize: 9 },
        },
      ],
      series: seriesData.map((s) => {
        const color = resolveColor(s.color) || t.accent
        return {
          name: s.name,
          type: "line",
          data: s.data,
          smooth: true,
          symbol: "none",
          lineStyle: { color, width: 1.5 },
          areaStyle: {
            color: {
              type: "linear",
              x: 0, y: 0, x2: 0, y2: 1,
              colorStops: [
                { offset: 0, color: color + "30" },
                { offset: 1, color: color + "05" },
              ],
            },
          },
        }
      }),
    })
  }

  seriesValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
