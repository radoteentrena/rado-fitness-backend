import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll-indicator"
export default class extends Controller {
  static targets = ["indicator"]

  connect() {
    this.checkScroll()
    this.element.addEventListener("scroll", this.checkScroll.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("scroll", this.checkScroll.bind(this))
  }

  checkScroll() {
    if (!this.hasIndicatorTarget) return
    
    const element = this.element
    const isScrollable = element.scrollWidth > element.clientWidth
    const isAtEnd = element.scrollLeft + element.clientWidth >= element.scrollWidth - 10
    
    // Show indicator if scrollable and not at the end
    if (isScrollable && !isAtEnd) {
      this.indicatorTarget.classList.remove("opacity-0")
      this.indicatorTarget.classList.add("opacity-100")
    } else {
      this.indicatorTarget.classList.remove("opacity-100")
      this.indicatorTarget.classList.add("opacity-0")
    }
  }
}
