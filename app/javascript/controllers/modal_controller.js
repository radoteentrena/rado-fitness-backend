import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop"]
  static values = {
    autoOpen: { type: Boolean, default: false }
  }

  connect() {
    if (this.autoOpenValue) {
      this.open()
    }
  }

  open() {
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    document.body.classList.remove("overflow-hidden")

    // If opened via Turbo Stream or standard navigation to a "new" route,
    // closing it might need to redirect back or remove the frame content.
    // For now, simple hide.
  }

  // Action for clicking outside the modal content
  closeBackground(event) {
    if (this.hasModalTarget && event.target === this.modalTarget) {
      this.close()
    }
  }

  closeWithKeyboard(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
