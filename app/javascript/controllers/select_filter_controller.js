import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "select"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const groups = this.selectTarget.querySelectorAll("optgroup")
    const ungroupedOptions = this.selectTarget.querySelectorAll("option:not([value=''])")

    if (groups.length > 0) {
      groups.forEach(group => {
        let anyVisible = false
        group.querySelectorAll("option").forEach(option => {
          const matches = !query || option.text.toLowerCase().includes(query)
          option.hidden = !matches
          if (matches) anyVisible = true
        })
        group.hidden = !anyVisible
      })
    } else {
      ungroupedOptions.forEach(option => {
        option.hidden = query.length > 0 && !option.text.toLowerCase().includes(query)
      })
    }
  }
}
