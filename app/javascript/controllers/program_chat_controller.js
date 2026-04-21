import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "frame"]

  connect() {
    this.boundReveal = this.revealPanel.bind(this)
    this.frameTarget.addEventListener("turbo:frame-load", this.boundReveal)
  }

  disconnect() {
    this.frameTarget.removeEventListener("turbo:frame-load", this.boundReveal)
  }

  open() {
    const chatUrl = this.frameTarget.dataset.chatUrl
    if (this.frameTarget.src !== chatUrl) {
      this.frameTarget.src = chatUrl
    } else {
      this.revealPanel()
    }
  }

  close() {
    this.panelTarget.classList.add("translate-x-full")
    this.panelTarget.classList.remove("translate-x-0")
  }

  revealPanel() {
    this.panelTarget.classList.remove("translate-x-full")
    this.panelTarget.classList.add("translate-x-0")
  }
}
