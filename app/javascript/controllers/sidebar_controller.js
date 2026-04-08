import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu"]

  openMobile() {
    this.mobileMenuTarget.showModal()
  }

  closeMobile() {
    this.mobileMenuTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.mobileMenuTarget) {
      this.mobileMenuTarget.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  // Legacy toggle for any remaining references
  toggle() {
    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.open ? this.closeMobile() : this.openMobile()
    }
  }
}
