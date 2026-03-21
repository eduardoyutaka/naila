import { Controller } from "@hotwired/stimulus"

// Plays audio alert for high severity events (>= 3)
export default class extends Controller {
  static values = {
    severity:  { type: Number, default: 0 },
    enabled:   { type: Boolean, default: true },
  }

  connect() {
    this.audioCtx = null
    this.maybeTrigger()
  }

  severityValueChanged() {
    this.maybeTrigger()
  }

  maybeTrigger() {
    if (!this.enabledValue || this.severityValue < 3) return
    this.playBeep()
  }

  async playBeep() {
    try {
      if (!this.audioCtx) {
        this.audioCtx = new (window.AudioContext || window.webkitAudioContext)()
      }

      const ctx = this.audioCtx
      const oscillator = ctx.createOscillator()
      const gain = ctx.createGain()

      oscillator.connect(gain)
      gain.connect(ctx.destination)

      // Higher severity = higher pitch
      oscillator.frequency.value = this.severityValue >= 4 ? 880 : 660
      oscillator.type = "sine"
      gain.gain.value = 0.15

      oscillator.start()
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5)
      oscillator.stop(ctx.currentTime + 0.5)
    } catch {
      // AudioContext blocked by browser autoplay policy — expected
    }
  }

  disconnect() {
    this.audioCtx?.close()
  }
}
