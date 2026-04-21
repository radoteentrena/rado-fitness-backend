import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "frame"]

  open() {
    const chatUrl = this.frameTarget.dataset.chatUrl
    if (this.frameTarget.getAttribute("src") !== chatUrl) {
      this.frameTarget.setAttribute("src", chatUrl)
    }
    this.revealPanel()
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
