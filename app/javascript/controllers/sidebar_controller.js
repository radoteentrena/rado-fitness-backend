import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop"]

  connect() {
    // Create backdrop element if it doesn't exist
    if (!this.hasBackdropTarget) {
      const backdrop = document.createElement("div")
      backdrop.className = "fixed inset-0 z-30 bg-gray-900/50 dark:bg-gray-900/80 hidden transition-opacity"
      backdrop.setAttribute("data-sidebar-target", "backdrop")
      backdrop.setAttribute("data-action", "click->sidebar#close")
      document.body.appendChild(backdrop)
    }
  }

  toggle() {
    if (this.sidebarTarget.classList.contains("-translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden")
      // Small timeout to allow transition to work
      setTimeout(() => this.backdropTarget.classList.remove("opacity-0"), 10)
    }
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden")
    }
  }
}
