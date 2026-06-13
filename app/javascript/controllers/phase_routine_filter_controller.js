import { Controller } from "@hotwired/stimulus"

// Filters the routine checkbox list inside the phase modal by gender / focus /
// level. Mirrors the routines page, which filters by `name ILIKE %term%`, so we
// match each row's name against the selected terms (AND across filters).
export default class extends Controller {
  static targets = ["filter", "row", "empty"]

  filter() {
    const terms = this.filterTargets
      .map((f) => f.value.trim().toLowerCase())
      .filter((v) => v.length > 0)

    let visible = 0
    this.rowTargets.forEach((row) => {
      const name = row.dataset.name || ""
      const match = terms.every((term) => name.includes(term))
      row.classList.toggle("hidden", !match)
      if (match) visible += 1
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visible !== 0)
    }
  }
}
