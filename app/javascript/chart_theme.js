// Reads a CSS custom property from the document root.
const css = (name) =>
  getComputedStyle(document.documentElement).getPropertyValue(`--color-${name}`).trim()

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
      filler: css("sky-500") + "26",   // ~15 % opacity
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
