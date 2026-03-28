import { Controller } from "@hotwired/stimulus"

// Severity → border colour (matches app-wide risk colour scheme)
const SEVERITY_COLORS = { 1: "#eab308", 2: "#f97316", 3: "#ef4444", 4: "#a855f7" }

// Compact chart for sensor readings over time (bar or line, configurable)
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    readings:   { type: Array, default: [] },  // [[iso8601, value], ...]
    unit:       { type: String, default: "" },
    chartType:  { type: String, default: "bar" }, // "bar" or "line"
    color:      { type: String, default: "#3b82f6" },
    thresholds: { type: Array, default: [] },  // [{ value, severity, label }]
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
    const color = this.colorValue
    const isBar = this.chartTypeValue === "bar"

    const series = isBar ? this.#barSeries(readings, color) : this.#lineSeries(readings, color)
    if (this.thresholdsValue.length > 0) {
      series.markLine = this.#thresholdMarkLines(this.thresholdsValue)
    }

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
        min: isBar ? 0 : undefined,
      },
      series: [series],
    })
  }

  readingsValueChanged() {
    if (!this.chart) return
    this.render()
  }

  // -- Private --

  #barSeries(readings, color) {
    return {
      type: "bar",
      data: readings.map(([ts, val]) => [ts, val]),
      barMaxWidth: 12,
      itemStyle: {
        borderRadius: [2, 2, 0, 0],
        color: {
          type: "linear",
          x: 0, y: 0, x2: 0, y2: 1,
          colorStops: [
            { offset: 0, color: this.#lighten(color) },
            { offset: 1, color },
          ],
        },
      },
    }
  }

  #lineSeries(readings, color) {
    return {
      type: "line",
      data: readings.map(([ts, val]) => [ts, val]),
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
  }

  #thresholdMarkLines(thresholds) {
    return {
      silent: true,
      symbol: ["none", "none"],
      animation: false,
      data: thresholds.map((t) => ({
        name: t.label,
        yAxis: t.value,
        lineStyle: { type: "dashed", color: SEVERITY_COLORS[t.severity] || "#94a3b8", width: 1.5, opacity: 0.8 },
        label: { show: true, position: "end", formatter: t.label, color: SEVERITY_COLORS[t.severity] || "#94a3b8", fontSize: 9 },
      })),
    }
  }

  #lighten(hex) {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    const l = (c) => Math.min(255, c + 40)
    return `#${l(r).toString(16).padStart(2, "0")}${l(g).toString(16).padStart(2, "0")}${l(b).toString(16).padStart(2, "0")}`
  }
}
