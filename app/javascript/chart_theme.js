// Reads a CSS custom property from the document root.
// Called at module evaluation time — safe because importmap modules are deferred
// and only run after the document (and its stylesheets) are fully parsed.
const css = (name) =>
  getComputedStyle(document.documentElement).getPropertyValue(`--color-${name}`).trim()

// Resolves a color value. If the value looks like a CSS token name (no "#" or "rgb" prefix),
// it is resolved from the document's custom properties. Otherwise returned as-is.
export function resolveColor(value) {
  if (!value) return value
  if (value.startsWith("#") || value.startsWith("rgb")) return value
  return css(value) || value
}

// Shared ECharts theme using design tokens from application.css.
// Consume individual properties rather than spreading the whole object to avoid
// accidental coupling to fields that may change.
export const CHART_THEME = {
  bg: "transparent",

  tooltip: {
    bg:    css("zinc-800"),
    border: css("white/10"),
    text:  css("white"),
    muted: css("zinc-400"),
  },

  axis: {
    line:  css("white/10"),
    label: css("zinc-400"),
    split: css("white/10"),
  },

  dataZoom: {
    border:  css("white/10"),
    bg:      css("zinc-900"),
    filler:  css("sky-500") + "26",   // ~15 % opacity
    handle:  css("sky-500"),
  },

  legend: {
    text: css("zinc-400"),
  },

  // Alarm severity level → stroke color
  severity: {
    1: css("risk-attention"),
    2: css("risk-alert"),
    3: css("risk-high"),
    4: css("risk-emergency"),
  },

  // Sensor type → fill color
  sensor: {
    pluviometer:     css("sensor-pluviometer"),
    river_gauge:     css("sensor-river-gauge"),
    weather_station: css("sensor-weather"),
    online:          css("sensor-online"),
    degraded:        css("sensor-degraded"),
    offline:         css("sensor-offline"),
  },

  accent: css("sky-500"),
}
