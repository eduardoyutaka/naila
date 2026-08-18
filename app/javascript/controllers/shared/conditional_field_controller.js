import { Controller } from "@hotwired/stimulus"

// Shows/hides a target field based on whether a trigger <select>'s current value is
// in an allow-list, clearing the field's own input when hidden so a stale value never
// rides along with a state it doesn't apply to.
export default class extends Controller {
  static targets = ["trigger", "field", "input"]
  static values = { show: { type: Array, default: [] } }

  connect() {
    this.toggle()
  }

  toggle() {
    const visible = this.showValue.includes(this.triggerTarget.value)
    this.fieldTarget.hidden = !visible
    if (!visible && this.hasInputTarget) this.inputTarget.value = ""
  }
}
