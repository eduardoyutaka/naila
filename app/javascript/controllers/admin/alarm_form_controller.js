import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["thresholdList", "thresholdTemplate", "emptyWarning", "submit", "stationSelect", "stationOption"]

  connect() {
    this.#updateSubmitState()
    this.filterStations()
  }

  // Shows only the station options configured for the currently selected basin
  // (hiding + deselecting the rest if the selection falls out of scope), so the
  // dropdown narrows as soon as a basin is picked. With no basin selected, every
  // configured station stays visible — the alarm's own basin-membership validation
  // is the actual source of truth at save time.
  filterStations() {
    if (!this.hasStationOptionTarget) return

    const basinSelect = this.element.querySelector("select[name='alarm[river_basin_id]']")
    const basinId = basinSelect?.value
    let selectedHidden = false

    this.stationOptionTargets.forEach(option => {
      if (!basinId) {
        option.hidden = false
        return
      }

      const basinIds = JSON.parse(option.dataset.basinIds || "[]").map(String)
      const matches = basinIds.includes(basinId)
      option.hidden = !matches
      if (!matches && option.selected) selectedHidden = true
    })

    if (selectedHidden && this.hasStationSelectTarget) this.stationSelectTarget.value = ""
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
