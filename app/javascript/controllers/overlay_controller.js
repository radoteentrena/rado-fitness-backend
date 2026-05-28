import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "backdrop"]
  static values = {
    autoOpen: { type: Boolean, default: false }
  }

  connect() {
    if (this.autoOpenValue) {
      this.open()
    }
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden")
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.remove("flex")
    document.body.classList.remove("overflow-hidden")

    // If opened via Turbo Stream or standard navigation to a "new" route,
    // closing it might need to redirect back or remove the frame content.
    // For now, simple hide.
  }

  // Action for clicking outside the overlay content
  closeBackground(event) {
    if (this.hasModalTarget && event.target === this.overlayTarget) {
      this.close()
    }
  }

  closeWithKeyboard(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
