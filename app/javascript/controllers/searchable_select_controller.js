import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "list", "option"]

  connect() {
    this.boundOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.boundOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutsideClick)
  }

  open() {
    this.listTarget.classList.remove("hidden")
  }

  close() {
    this.listTarget.classList.add("hidden")
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    let hasVisible = false

    this.optionTargets.forEach(option => {
      const matches = option.dataset.name.toLowerCase().includes(query)
      option.classList.toggle("hidden", !matches)
      if (matches) hasVisible = true
    })

    this.hiddenTarget.value = ""
    this.open()
  }

  select(event) {
    const btn = event.currentTarget
    this.inputTarget.value = btn.dataset.name
    this.hiddenTarget.value = btn.dataset.value
    this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.close()
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
      if (!this.hiddenTarget.value) this.inputTarget.value = ""
    }
  }
}
