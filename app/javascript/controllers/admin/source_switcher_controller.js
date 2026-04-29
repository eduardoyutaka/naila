import { Controller } from "@hotwired/stimulus"

// Dropdown switcher that swaps data on a nested forecast-chart controller.
// Stores all sources' chart data in a single JSON value and updates the
// target element's forecasts-value attribute on selection change,
// triggering the forecast-chart controller's reactive re-render.
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    sources: { type: Object, default: {} },
  }

  switch(event) {
    const data = this.sourcesValue[event.target.value]
    if (!data || !this.hasChartTarget) return

    this.chartTarget.setAttribute(
      "data-admin--forecast-chart-forecasts-value",
      JSON.stringify(data)
    )
  }
}
