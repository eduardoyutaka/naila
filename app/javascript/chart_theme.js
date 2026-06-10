// All time-axis charts display in São Paulo time regardless of the viewer's
// browser timezone. ECharts has no native timezone option, so we format the
// absolute instant (epoch-ms or ISO string) with Intl pinned to America/Sao_Paulo.
const SP_TZ = "America/Sao_Paulo"
const _spTime = new Intl.DateTimeFormat("pt-BR", { timeZone: SP_TZ, hour: "2-digit", minute: "2-digit", hour12: false })
const _spDate = new Intl.DateTimeFormat("pt-BR", { timeZone: SP_TZ, day: "2-digit", month: "2-digit" })

// "HH:mm" in São Paulo
export function spTime(value) {
  return _spTime.format(new Date(value))
}

// "dd/mm HH:mm" in São Paulo
export function spDateTime(value) {
  const d = new Date(value)
  return `${_spDate.format(d)} ${_spTime.format(d)}`
}

// Reads a CSS custom property from the document root.
const css = (name) =>
  getComputedStyle(document.documentElement).getPropertyValue(`--color-${name}`).trim()

// Resolves ANY CSS color (oklch, hex, rgb, named) to [r, g, b] by letting the
// browser paint it and reading the pixel back. Tailwind 4 palette tokens are
// oklch(), which canvas addColorStop accepts as a solid color but NOT when a
// hex-alpha suffix is concatenated (`oklch(...)cc` → SyntaxError). Routing alpha
// through here keeps gradients valid regardless of the source color space.
const _probe = document.createElement("canvas")
_probe.width = _probe.height = 1
const _probeCtx = _probe.getContext("2d", { willReadFrequently: true })

function toRgb(color) {
  _probeCtx.clearRect(0, 0, 1, 1)
  _probeCtx.fillStyle = "#000" // fallback if `color` is unparseable
  _probeCtx.fillStyle = color
  _probeCtx.fillRect(0, 0, 1, 1)
  const [r, g, b] = _probeCtx.getImageData(0, 0, 1, 1).data
  return [r, g, b]
}

// Canvas-safe `rgba()` for any CSS color + alpha (0..1).
export function withAlpha(color, alpha) {
  const [r, g, b] = toRgb(color)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

// Lightens any CSS color toward white by a flat per-channel amount (0..255).
export function lighten(color, amount = 40) {
  const [r, g, b] = toRgb(color)
  const up = (c) => Math.min(255, c + amount)
  return `rgb(${up(r)}, ${up(g)}, ${up(b)})`
}

// Resolves a color value. If the value looks like a CSS token name (no "#" or "rgb" prefix),
// it is resolved from the document's custom properties. Otherwise returned as-is.
export function resolveColor(value) {
  if (!value) return value
  if (value.startsWith("#") || value.startsWith("rgb")) return value
  return css(value) || value
}

// Builds the shared ECharts theme from design tokens. This is a FUNCTION (not a frozen
// const) so it re-reads the CSS custom properties on every call — a runtime light/dark
// switch is therefore picked up the next time a chart renders. Surface/text/axis colors
// use the semantic --color-chart-* tokens (which flip under `.dark`); severity and sensor
// colors are theme-independent palette tokens.
export function chartTheme() {
  return {
    bg: "transparent",

    tooltip: {
      bg:     css("chart-surface"),
      border: css("chart-border"),
      text:   css("chart-text"),
      muted:  css("chart-muted"),
    },

    axis: {
      line:  css("chart-axis"),
      label: css("chart-muted"),
      split: css("chart-split"),
    },

    dataZoom: {
      border: css("chart-border"),
      bg:     css("chart-zoom-bg"),
      filler: withAlpha(css("sky-500"), 0.15),
      handle: css("sky-500"),
    },

    legend: {
      text: css("chart-muted"),
    },

    // Alarm severity level → stroke color
    severity: {
      1: css("risk-attention"),
      2: css("risk-alert"),
      3: css("risk-high"),
      4: css("risk-emergency"),
    },

    // Sensor type / status → color
    sensor: {
      pluviometer:     css("sensor-pluviometer"),
      weather_station: css("sensor-weather"),
      online:          css("sensor-online"),
      degraded:        css("sensor-degraded"),
      offline:         css("sensor-offline"),
    },

    accent: css("sky-500"),
  }
}
