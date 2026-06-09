import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    screen: { type: String, default: "choice" }
  }

  static targets = ["choiceScreen", "existingScreen", "newScreen"]

  connect() {
    this.screenValueChanged(this.screenValue)
  }

  screenValueChanged(value) {
    this.choiceScreenTargets.forEach(el => el.classList.toggle("hidden", value !== "choice"))
    this.existingScreenTargets.forEach(el => el.classList.toggle("hidden", value !== "existing"))
    this.newScreenTargets.forEach(el => el.classList.toggle("hidden", value !== "new"))
  }

  selectExisting() {
    this.screenValue = "existing"
  }

  selectNew() {
    this.screenValue = "new"
  }

  back() {
    this.screenValue = "choice"
  }
}
