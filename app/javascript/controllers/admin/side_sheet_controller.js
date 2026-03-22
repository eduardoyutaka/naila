import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "frame"]

  open(sensorId) {
    this.frameTarget.src = `/admin/sensor_stations/${sensorId}`
    this.element.classList.remove("hidden")
  }

  close() {
    this.element.classList.add("hidden")
    this.frameTarget.removeAttribute("src")
    this.frameTarget.innerHTML = ""
  }
}
