import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// ActionCable subscription manager — subscribes to channels and dispatches
// custom events so other Stimulus controllers can react to real-time updates.
export default class extends Controller {
  static values = {
    channel: { type: String, default: "" },
    params:  { type: Object, default: {} },
  }

  connect() {
    if (!this.channelValue) return

    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: this.channelValue, ...this.paramsValue },
      {
        received: (data) => this.handleReceived(data),
        connected: () => this.dispatch("connected"),
        disconnected: () => this.dispatch("disconnected"),
      }
    )
  }

  handleReceived(data) {
    // Dispatch a custom Stimulus event with the payload
    this.dispatch("message", { detail: data })

    // If the data contains a Turbo Stream, let Turbo handle it
    if (typeof data === "string" && data.includes("<turbo-stream")) {
      Turbo.renderStreamMessage(data)
    }
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }
}
