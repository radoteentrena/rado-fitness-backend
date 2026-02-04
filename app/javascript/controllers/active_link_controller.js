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
    return ["bg-whiteish", "text-blackish", "shadow-sm", "dark:bg-shadow", "dark:text-whiteish"]
  }

  get inactiveClasses() {
    return ["text-graphite", "hover:bg-background-light", "dark:text-muted", "dark:hover:bg-shadow/50", "dark:hover:text-whiteish"]
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
