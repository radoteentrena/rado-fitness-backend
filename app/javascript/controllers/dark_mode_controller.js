import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "text"]

  connect() {
    this.checkPreference()
  }

  toggle() {
    if (document.documentElement.classList.contains("dark")) {
      document.documentElement.classList.remove("dark")
      localStorage.theme = "light"
    } else {
      document.documentElement.classList.add("dark")
      localStorage.theme = "dark"
    }
    this.updateUI()
  }

  checkPreference() {
    if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
    this.updateUI()
  }

  updateUI() {
    const isDark = document.documentElement.classList.contains("dark")
    // Update icon if target exists (optional)
    if (this.hasIconTarget) {
      this.iconTarget.textContent = isDark ? "light_mode" : "dark_mode"
    }
  }
}
