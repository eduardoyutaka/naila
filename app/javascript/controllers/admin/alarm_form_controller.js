import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["thresholdList", "thresholdTemplate", "emptyWarning", "submit"]

  connect() {
    this.#updateSubmitState()
  }

  addThreshold() {
    const template = this.thresholdTemplateTarget
    const clone = template.content.cloneNode(true)
    const timestamp = Date.now()

    clone.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace("NEW_RECORD", timestamp)
    })

    this.thresholdListTarget.appendChild(clone)
    this.#updateSubmitState()
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

    this.#updateSubmitState()
  }

  #updateSubmitState() {
    const visibleRows = this.thresholdListTarget.querySelectorAll(".threshold-row:not([hidden])").length
    const isEmpty = visibleRows === 0

    if (this.hasSubmitTarget) this.submitTarget.disabled = isEmpty

    if (this.hasEmptyWarningTarget) this.emptyWarningTarget.hidden = !isEmpty
  }
}
