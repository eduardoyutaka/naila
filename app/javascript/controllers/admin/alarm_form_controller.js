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

    // Metric/Anomaly fields
    if (this.hasMetricFieldsTarget) {
      this.metricFieldsTarget.hidden = type === "composite"
    }

    // Composite fields
    if (this.hasCompositeFieldsTarget) {
      this.compositeFieldsTarget.hidden = type !== "composite"
    }

    // Threshold fields (metric only, not anomaly)
    if (this.hasThresholdFieldsTarget) {
      this.thresholdFieldsTarget.hidden = type !== "metric"
    }

    // Anomaly fields
    if (this.hasAnomalyFieldsTarget) {
      this.anomalyFieldsTarget.hidden = type !== "anomaly_detection"
    }
  }
}
