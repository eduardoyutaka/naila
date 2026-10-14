import { Controller } from "@hotwired/stimulus"

// Shows/hides each field target based on whether a trigger <select>'s current value
// is in that field's own allow-list (data-show-value) — lets one trigger drive several
// mutually-exclusive fields, each deciding independently whether it applies.
export default class extends Controller {
  static targets = ["trigger", "field"]

  connect() {
    this.toggle()
  }

  toggle() {
    this.fieldTargets.forEach(field => {
      const showValues = JSON.parse(field.dataset.showValue || "[]")
      const visible = showValues.includes(this.triggerTarget.value)
      field.hidden = !visible

      // Clear every form element in the field, not just one tagged input — so a field
      // with more than one input can't leak a stale value once it's hidden.
      if (!visible) {
        field.querySelectorAll("input, select, textarea").forEach(el => el.value = "")
      }
    })
  }
}
