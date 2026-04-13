import { Controller } from "@hotwired/stimulus"

// Auto-submits the enclosing form when an input changes.
// Selects/checkboxes submit immediately; text inputs are debounced.
//
// Usage:
//   <select data-controller="shared--auto-submit"
//           data-action="change->shared--auto-submit#submit">
//
//   <input  data-controller="shared--auto-submit"
//           data-action="input->shared--auto-submit#submitDebounced"
//           data-shared--auto-submit-delay-value="300">
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  submit() {
    this.element.closest("form")?.requestSubmit()
  }

  submitDebounced() {
    clearTimeout(this._timeout)
    this._timeout = setTimeout(() => this.submit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this._timeout)
  }
}
