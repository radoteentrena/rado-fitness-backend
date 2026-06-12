import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calories", "protein", "fats", "carbs", "activity", "save"]
  static values = { bmr: Number }

  connect() {
    this.initialState = this.currentState()
  }

  caloriesChanged() {
    const calories = parseInt(this.caloriesTarget.value, 10)
    if (!isNaN(calories) && calories > 0) {
      this.proteinTarget.value = Math.round((calories * 0.30) / 4)
      this.fatsTarget.value = Math.round((calories * 0.30) / 9)
      this.carbsTarget.value = Math.round((calories * 0.40) / 4)
    }
    this.toggleSave()
  }

  macroChanged() {
    const protein = parseInt(this.proteinTarget.value, 10) || 0
    const fats = parseInt(this.fatsTarget.value, 10) || 0
    const carbs = parseInt(this.carbsTarget.value, 10) || 0
    this.caloriesTarget.value = protein * 4 + carbs * 4 + fats * 9
    this.toggleSave()
  }

  applyActivity() {
    const factor = parseFloat(this.activityTarget.value)
    if (!this.bmrValue || isNaN(factor)) return
    this.caloriesTarget.value = Math.round(this.bmrValue * factor)
    this.caloriesChanged()
  }

  toggleSave() {
    if (!this.hasSaveTarget) return
    this.saveTarget.classList.toggle("hidden", this.currentState() === this.initialState)
  }

  currentState() {
    return [this.caloriesTarget, this.proteinTarget, this.fatsTarget, this.carbsTarget]
      .map((target) => target.value)
      .join("|")
  }
}
