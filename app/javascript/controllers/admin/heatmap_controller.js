import { Controller } from "@hotwired/stimulus"
import { chartTheme } from "chart_theme"

// Calendar heatmap for rainfall intensity by hour/day
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    data:  { type: Array, default: [] }, // [[hour(0-23), day(0-6), value], ...]
    title: { type: String, default: "" },
    unit:  { type: String, default: "mm" },
  }

  static HOURS = Array.from({ length: 24 }, (_, i) => `${String(i).padStart(2, "0")}h`)
  static DAYS = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

  async connect() {
    const echarts = await import("echarts")
    this.echarts = echarts

    this.chart = echarts.init(this.chartTarget, null, { renderer: "canvas" })
    this.render()

    this.resizeObserver = new ResizeObserver(() => this.chart.resize())
    this.resizeObserver.observe(this.chartTarget)

    this.onThemeChange = () => this.render()
    window.addEventListener("theme:changed", this.onThemeChange)
  }

  disconnect() {
    window.removeEventListener("theme:changed", this.onThemeChange)
    this.resizeObserver?.disconnect()
    this.chart?.dispose()
  }

  render() {
    const t = chartTheme()
    const dark = document.documentElement.classList.contains("dark")
    const data = this.dataValue
    const maxVal = Math.max(...data.map((d) => d[2]), 1)
    // Heat ramp: low end blends into the surface (light blue on light, near-black on dark)
    const heatRamp = dark
      ? ["#111827", "#1e3a5f", "#3b82f6", "#eab308", "#ef4444"]
      : ["#eff6ff", "#bfdbfe", "#3b82f6", "#eab308", "#ef4444"]

    this.chart.setOption({
      backgroundColor: "transparent",
      title: {
        text: this.titleValue,
        left: "center",
        textStyle: { color: t.tooltip.text, fontSize: 13, fontWeight: 600 },
      },
      tooltip: {
        backgroundColor: t.tooltip.bg,
        borderColor: t.tooltip.border,
        textStyle: { color: t.tooltip.text, fontSize: 11 },
        formatter: (params) => {
          const [hour, day, val] = params.data
          return `${this.constructor.DAYS[day]} ${this.constructor.HOURS[hour]}<br/>
                  <strong>${val} ${this.unitValue}</strong>`
        },
      },
      grid: { top: 36, right: 60, bottom: 24, left: 48 },
      xAxis: {
        type: "category",
        data: this.constructor.HOURS,
        axisLine: { lineStyle: { color: t.axis.line } },
        axisLabel: { color: t.axis.label, fontSize: 9 },
        splitArea: { show: false },
      },
      yAxis: {
        type: "category",
        data: this.constructor.DAYS,
        axisLine: { lineStyle: { color: t.axis.line } },
        axisLabel: { color: t.axis.label, fontSize: 10 },
        splitArea: { show: false },
      },
      visualMap: {
        min: 0,
        max: maxVal,
        orient: "vertical",
        right: 0,
        top: "center",
        itemHeight: 100,
        textStyle: { color: t.axis.label, fontSize: 9 },
        inRange: {
          color: heatRamp,
        },
      },
      series: [{
        type: "heatmap",
        data,
        emphasis: {
          itemStyle: { shadowBlur: 6, shadowColor: "rgba(59, 130, 246, 0.5)" },
        },
      }],
    })
  }

  dataValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
