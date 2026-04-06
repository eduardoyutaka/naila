import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["metricFields", "compositeFields", "thresholdFields", "anomalyFields"]
  static values = { type: String }

  connect() {
    this.toggleSections()
  }

  typeChanged(event) {
    this.typeValue = event.target.value
    this.toggleSections()
  }

  toggleSections() {
    const type = this.typeValue
    this.#toggle(this.metricFieldsTarget, type !== "composite")
    this.#toggle(this.compositeFieldsTarget, type === "composite")
    this.#toggle(this.thresholdFieldsTarget, type === "metric")
    this.#toggle(this.anomalyFieldsTarget, type === "anomaly_detection")
  }

  #toggle(target, visible) {
    target.hidden = !visible
    target.querySelectorAll("input, select, textarea").forEach(el => {
      el.disabled = !visible
    })
  }
}
