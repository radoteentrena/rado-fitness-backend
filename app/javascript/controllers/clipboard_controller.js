import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values = { success: { type: String, default: "¡Copiado!" } }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value).then(() => {
      const original = this.buttonTarget.textContent
      this.buttonTarget.textContent = this.successValue
      setTimeout(() => { this.buttonTarget.textContent = original }, 2000)
    })
  }
}
