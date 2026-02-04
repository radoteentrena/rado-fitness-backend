import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]
  static classes = ["active", "inactive"]

  connect() {
    this.updateActiveState()
  }

  updateActiveState() {
    const currentPath = window.location.pathname

    this.linkTargets.forEach(link => {
      const href = link.getAttribute("href")
      let isActive = false

      if (href === "/admin") {
        isActive = currentPath === "/admin"
      } else if (href && href !== "#") {
        isActive = currentPath.startsWith(href)
      }

      if (isActive) {
        link.classList.remove(...this.inactiveClasses)
        link.classList.add(...this.activeClasses)
      } else {
        link.classList.remove(...this.activeClasses)
        link.classList.add(...this.inactiveClasses)
      }
    })
  }

  get activeClasses() {
    return ["bg-white", "text-black", "shadow-sm", "dark:bg-slate-800", "dark:text-white"]
  }

  get inactiveClasses() {
    return ["text-slate-600", "hover:bg-slate-200", "dark:text-slate-400", "dark:hover:bg-slate-700"]
  }

  initialize() {
    this.updateHandler = this.updateActiveState.bind(this)
    // turbo:load fires on initial load and after a visit (including frame advance)
    document.addEventListener("turbo:load", this.updateHandler)
    // turbo:frame-load fires when a frame finishes loading
    document.addEventListener("turbo:frame-load", this.updateHandler)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.updateHandler)
    document.removeEventListener("turbo:frame-load", this.updateHandler)
  }
}
