import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide", "dot"]
  static values = {
    current: { type: Number, default: 0 },
    interval: { type: Number, default: 4500 }
  }

  connect() {
    this.total = this.slideTargets.length
    this.updateDots()
    this.startAutoplay()

    this.boundStop = this.stopAutoplay.bind(this)
    this.boundStart = this.startAutoplay.bind(this)
    this.element.addEventListener("mouseenter", this.boundStop)
    this.element.addEventListener("mouseleave", this.boundStart)

    this._touchStartX = 0
    this.element.addEventListener("touchstart", (e) => {
      this._touchStartX = e.touches[0].clientX
    }, { passive: true })
    this.element.addEventListener("touchend", (e) => {
      const diff = this._touchStartX - e.changedTouches[0].clientX
      if (Math.abs(diff) > 50) diff > 0 ? this.next() : this.prev()
    }, { passive: true })
  }

  disconnect() {
    this.stopAutoplay()
    this.element.removeEventListener("mouseenter", this.boundStop)
    this.element.removeEventListener("mouseleave", this.boundStart)
  }

  next() {
    this.currentValue = (this.currentValue + 1) % this.total
  }

  prev() {
    this.currentValue = (this.currentValue - 1 + this.total) % this.total
  }

  goTo(event) {
    this.currentValue = parseInt(event.currentTarget.dataset.index)
  }

  currentValueChanged() {
    this.trackTarget.style.transform = `translateX(-${this.currentValue * 100}%)`
    this.updateDots()
  }

  updateDots() {
    if (!this.hasDotTarget) return
    this.dotTargets.forEach((dot, i) => {
      const active = i === this.currentValue
      dot.classList.toggle("w-6", active)
      dot.classList.toggle("w-2", !active)
      dot.classList.toggle("bg-saffron", active)
      dot.classList.toggle("bg-white/40", !active)
    })
  }

  startAutoplay() {
    this.stopAutoplay()
    this.timer = setInterval(() => this.next(), this.intervalValue)
  }

  stopAutoplay() {
    if (this.timer) clearInterval(this.timer)
  }
}
