import { Controller } from "@hotwired/stimulus"

// Combobox (autocomplete) controller.
// Filters a list of options based on text input, supports keyboard navigation.
//
// Usage:
//   <div data-controller="shared--combobox">
//     <input type="text"
//            data-shared--combobox-target="input"
//            data-action="input->shared--combobox#filter keydown->shared--combobox#keydown focus->shared--combobox#open">
//     <div popover data-shared--combobox-target="list" role="listbox">
//       <div role="option" data-shared--combobox-target="option" data-value="1">Option 1</div>
//       <div role="option" data-shared--combobox-target="option" data-value="2">Option 2</div>
//     </div>
//     <input type="hidden" data-shared--combobox-target="hidden" name="field_name">
//   </div>
export default class extends Controller {
  static targets = ["input", "list", "option", "hidden"]

  connect() {
    this._focusedIndex = -1
  }

  open() {
    if (!this.listTarget.matches(":popover-open")) {
      this.listTarget.showPopover()
    }
  }

  close() {
    if (this.listTarget.matches(":popover-open")) {
      this.listTarget.hidePopover()
    }
    this._focusedIndex = -1
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    let visibleCount = 0

    this.optionTargets.forEach((option) => {
      const text = option.textContent.toLowerCase()
      const match = text.includes(query)
      option.hidden = !match
      if (match) visibleCount++
    })

    if (visibleCount > 0) {
      this.open()
    } else {
      this.close()
    }
    this._focusedIndex = -1
  }

  keydown(event) {
    const visible = this.optionTargets.filter((o) => !o.hidden)
    if (!visible.length) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.open()
        this._focusedIndex = Math.min(this._focusedIndex + 1, visible.length - 1)
        this._highlightOption(visible)
        break
      case "ArrowUp":
        event.preventDefault()
        this._focusedIndex = Math.max(this._focusedIndex - 1, 0)
        this._highlightOption(visible)
        break
      case "Enter":
        event.preventDefault()
        if (this._focusedIndex >= 0 && visible[this._focusedIndex]) {
          this._selectOption(visible[this._focusedIndex])
        }
        break
      case "Escape":
        this.close()
        this.inputTarget.focus()
        break
    }
  }

  select(event) {
    const option = event.currentTarget
    this._selectOption(option)
  }

  // Private

  _selectOption(option) {
    this.inputTarget.value = option.textContent.trim()
    if (this.hasHiddenTarget) {
      this.hiddenTarget.value = option.dataset.value || option.textContent.trim()
    }
    this.close()
    this.dispatch("change", { detail: { value: option.dataset.value, text: option.textContent.trim() } })
  }

  _highlightOption(visible) {
    visible.forEach((o, i) => {
      o.classList.toggle("bg-blue-500", i === this._focusedIndex)
      o.classList.toggle("text-white", i === this._focusedIndex)
    })
  }
}
