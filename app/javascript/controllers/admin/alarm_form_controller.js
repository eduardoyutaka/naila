import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["metricFields", "compositeFields", "thresholdFields", "anomalyFields", "thresholdList", "thresholdTemplate"]
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

  addThreshold() {
    const template = this.thresholdTemplateTarget
    const clone = template.content.cloneNode(true)
    const timestamp = Date.now()

    clone.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace("NEW_RECORD", timestamp)
    })

    this.thresholdListTarget.appendChild(clone)
  }

  removeThreshold(event) {
    const row = event.currentTarget.closest(".threshold-row")
    const isPersisted = event.currentTarget.dataset.persisted === "true"

    if (isPersisted) {
      // Mark for deletion and hide — Rails will delete on save
      const destroyField = row.querySelector("[data-destroy-field]")
      if (destroyField) destroyField.value = "1"
      row.hidden = true
      row.querySelectorAll("input, select").forEach(el => el.disabled = true)
    } else {
      row.remove()
    }
  }

  #toggle(target, visible) {
    target.hidden = !visible
    target.querySelectorAll("input, select, textarea").forEach(el => {
      el.disabled = !visible
    })
  }
}
