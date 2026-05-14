import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.element.scrollIntoView({ behavior: "smooth", block: "start" })
    }, 100)
  }
}
