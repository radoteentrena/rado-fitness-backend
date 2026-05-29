import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static values = { url: String }

  connect() {
    this.dragging = null
    this.placeholder = null
  }

  dragstart(event) {
    // Don't drag when interacting with buttons, links, inputs, or forms
    if (event.target.closest("a, button, input, select, textarea, form")) {
      event.preventDefault()
      return
    }

    this.dragging = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "")

    // Delay opacity change so the drag ghost renders correctly
    requestAnimationFrame(() => {
      if (this.dragging) this.dragging.style.opacity = "0.4"
    })
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.currentTarget
    if (!target || target === this.dragging) return

    const rect = target.getBoundingClientRect()
    const midY = rect.top + rect.height / 2

    if (event.clientY < midY) {
      this.element.insertBefore(this.dragging, target)
    } else {
      this.element.insertBefore(this.dragging, target.nextElementSibling)
    }
  }

  dragend(event) {
    if (this.dragging) this.dragging.style.opacity = ""
    this.dragging = null
    this.saveOrder()
  }

  saveOrder() {
    const ids = this.itemTargets.map(item => item.dataset.exerciseId)
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ order: ids })
    }).then(response => {
      if (response.ok) {
        // Update the order_index badges in the DOM without a full reload
        this.itemTargets.forEach((item, index) => {
          const badge = item.querySelector(".order-index-badge")
          if (badge) badge.textContent = index + 1
        })
      }
    })
  }
}
