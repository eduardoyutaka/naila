import { Controller } from "@hotwired/stimulus"

// Wraps a native <dialog> element with open/close actions.
// Focus trapping, Escape-to-close, and backdrop are handled natively.
//
// Usage:
//   <div data-controller="shared--dialog">
//     <button data-action="shared--dialog#open">Open</button>
//     <dialog data-shared--dialog-target="dialog" class="...">
//       <button data-action="shared--dialog#close">Close</button>
//     </dialog>
//   </div>
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  // Close when clicking the backdrop (the <dialog> element itself, not its children)
  backdropClose(event) {
    if (event.target === this.dialogTarget) {
      this.dialogTarget.close()
    }
  }
}
