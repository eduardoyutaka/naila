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
    bg:    css("naila-elevated"),
    border: css("naila-border"),
    text:  css("naila-text"),
    muted: css("naila-text-muted"),
  },

  axis: {
    line:  css("naila-border"),
    label: css("naila-text-muted"),
    split: css("naila-border"),
  },

  dataZoom: {
    border:  css("naila-border"),
    bg:      css("naila-surface"),
    filler:  css("naila-accent") + "26",   // ~15 % opacity
    handle:  css("naila-accent"),
  },

  legend: {
    text: css("naila-text-muted"),
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

  accent: css("naila-accent"),
}
