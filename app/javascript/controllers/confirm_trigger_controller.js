import { Controller } from "@hotwired/stimulus"

// Attached to each admin delete link. Intercepts the click before Turbo's
// document-level delegation and asks the shared confirm modal to open.
export default class extends Controller {
  connect() {
    this.element.addEventListener("click", this.intercept)
  }

  disconnect() {
    this.element.removeEventListener("click", this.intercept)
  }

  intercept = (event) => {
    event.preventDefault()
    event.stopPropagation()

    window.dispatchEvent(new CustomEvent("admin:confirm", {
      detail: {
        title: this.element.dataset.confirmTitle || "Eliminar",
        message: this.element.dataset.confirmMessage || "",
        mode: this.element.dataset.confirmMode || "confirm",
        href: this.element.href
      }
    }))
  }
}
