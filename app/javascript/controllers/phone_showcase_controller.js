import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide"]
  static values = {
    hold: { type: Number, default: 3500 },
    duration: { type: Number, default: 650 }
  }

  connect() {
    this.index = 0
    this.total = this.slideTargets.length
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.observer = new IntersectionObserver(([entry]) => {
      entry.isIntersecting ? this.start() : this.stop()
    }, { threshold: 0.3 })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.stop()
    if (this.observer) this.observer.disconnect()
  }

  start() {
    this.stop()
    this.timer = setInterval(() => this.next(), this.holdValue)
  }

  stop() {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }

  next() {
    if (this.index >= this.total - 1) this.resetToStart()
    this.index += 1
    this.trackTarget.style.transition = `transform ${this.durationValue}ms cubic-bezier(0.16, 1, 0.3, 1)`
    this.trackTarget.style.transform = `translateX(-${this.index * 100}%)`

    if (this.index === this.total - 1) {
      this.trackTarget.addEventListener("transitionend", () => this.resetToStart(), { once: true })
    }
  }

  resetToStart() {
    this.trackTarget.style.transition = "none"
    this.index = 0
    this.trackTarget.style.transform = "translateX(0)"
    // Force reflow so the jump back to the first slide isn't animated
    void this.trackTarget.offsetWidth
  }
}
