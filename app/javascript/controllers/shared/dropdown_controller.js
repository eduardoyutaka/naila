import { Controller } from "@hotwired/stimulus"

// Dropdown menu using the Popover API with keyboard navigation.
//
// Usage:
//   <div data-controller="shared--dropdown">
//     <button popovertarget="menu-id" data-shared--dropdown-target="button">Menu</button>
//     <div popover id="menu-id" role="menu"
//          data-shared--dropdown-target="menu"
//          data-action="keydown->shared--dropdown#keydown">
//       <a role="menuitem" href="/a">Item A</a>
//       <a role="menuitem" href="/b">Item B</a>
//     </div>
//   </div>
export default class extends Controller {
  static targets = ["menu", "button"]

  keydown(event) {
    const items = [...this.menuTarget.querySelectorAll('[role="menuitem"]:not([aria-disabled="true"])')]
    if (!items.length) return

    const current = document.activeElement
    const index = items.indexOf(current)

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        items[(index + 1) % items.length]?.focus()
        break
      case "ArrowUp":
        event.preventDefault()
        items[(index - 1 + items.length) % items.length]?.focus()
        break
      case "Home":
        event.preventDefault()
        items[0]?.focus()
        break
      case "End":
        event.preventDefault()
        items[items.length - 1]?.focus()
        break
      case "Escape":
        this.menuTarget.hidePopover()
        this.buttonTarget.focus()
        break
    }
  }
}
