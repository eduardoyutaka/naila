import { Controller } from "@hotwired/stimulus"

// Animated counting number for dashboard stats
export default class extends Controller {
  static values = {
    value:    { type: Number, default: 0 },
    duration: { type: Number, default: 800 },
  }

  connect() {
    this.currentDisplay = 0
    this.animateTo(this.valueValue)
  }

  valueValueChanged(newVal, oldVal) {
    if (oldVal === undefined) return
    this.animateTo(newVal)
  }

  animateTo(target) {
    const start = this.currentDisplay
    const diff = target - start
    if (diff === 0) return

    const duration = this.durationValue
    const startTime = performance.now()

    const step = (now) => {
      const elapsed = now - startTime
      const progress = Math.min(elapsed / duration, 1)
      // ease-out cubic
      const eased = 1 - Math.pow(1 - progress, 3)

      this.currentDisplay = Math.round(start + diff * eased)
      this.element.textContent = this.currentDisplay.toLocaleString("pt-BR")

      if (progress < 1) {
        this.animationFrame = requestAnimationFrame(step)
      }
    }

    cancelAnimationFrame(this.animationFrame)
    this.animationFrame = requestAnimationFrame(step)
  }

  disconnect() {
    cancelAnimationFrame(this.animationFrame)
  }
}
