import { Controller } from "@hotwired/stimulus"
import { chartTheme } from "chart_theme"

// Semi-circular gauge for zone risk score (0–100%)
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    score: { type: Number, default: 0 },
    label: { type: String, default: "" },
  }

  static RISK_COLORS = [
    [0.20, "#22c55e"],  // Vigilância — green
    [0.40, "#eab308"],  // Atenção — yellow
    [0.60, "#f97316"],  // Alerta — orange
    [0.80, "#ef4444"],  // Alarme — red
    [1.00, "#a855f7"],  // Emergência — purple
  ]

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
    const score = this.scoreValue
    const percent = Math.round(score * 100)

    this.chart.setOption({
      series: [{
        type: "gauge",
        startAngle: 180,
        endAngle: 0,
        min: 0,
        max: 100,
        radius: "100%",
        center: ["50%", "75%"],
        axisLine: {
          lineStyle: {
            width: 14,
            color: this.constructor.RISK_COLORS,
          },
        },
        axisTick: { show: false },
        splitLine: { show: false },
        axisLabel: { show: false },
        pointer: {
          width: 4,
          length: "55%",
          itemStyle: { color: t.tooltip.text },
        },
        anchor: {
          show: true,
          size: 6,
          itemStyle: { borderColor: t.axis.line, borderWidth: 2, color: t.tooltip.bg },
        },
        title: {
          show: true,
          offsetCenter: [0, "30%"],
          color: t.axis.label,
          fontSize: 10,
        },
        detail: {
          valueAnimation: true,
          formatter: "{value}%",
          offsetCenter: [0, "0%"],
          color: t.tooltip.text,
          fontSize: 20,
          fontWeight: 700,
          fontFamily: "Inter, system-ui, sans-serif",
        },
        data: [{ value: percent, name: this.labelValue }],
      }],
    })
  }

  scoreValueChanged() {
    if (!this.chart) return
    this.render()
  }
}
