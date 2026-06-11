import { Controller } from "@hotwired/stimulus"

// Registered on #admin_toast_container. Removes each toast once its
// fade-out animation finishes so the fixed container stays clean.
export default class extends Controller {
  connect() {
    this.element.addEventListener("animationend", this.handleAnimationEnd)
  }

  disconnect() {
    this.element.removeEventListener("animationend", this.handleAnimationEnd)
  }

  handleAnimationEnd = (event) => {
    if (event.animationName !== "toast-fade") return
    event.target.remove()
  }
}
