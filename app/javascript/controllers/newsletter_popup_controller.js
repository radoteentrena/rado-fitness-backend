import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["emailInput"]
  static values = {
    delay: { type: Number, default: 3500 },
    storageKey: { type: String, default: "rte_nl_v1" },
    redirectUrl: String
  }

  connect() {
    this._timer = setTimeout(() => this.open(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this._timer)
    document.removeEventListener('keydown', this._escHandler)
  }

  open() {
    if (sessionStorage.getItem(this.storageKeyValue)) return
    this.element.classList.add('is-open')
    this._escHandler = (e) => { if (e.key === 'Escape') this.close() }
    document.addEventListener('keydown', this._escHandler)
    setTimeout(() => {
      if (this.hasEmailInputTarget) this.emailInputTarget.focus()
    }, 340)
  }

  close() {
    this.element.classList.remove('is-open')
    sessionStorage.setItem(this.storageKeyValue, '1')
    document.removeEventListener('keydown', this._escHandler)
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  submit(event) {
    event.preventDefault()
    const email = this.hasEmailInputTarget ? this.emailInputTarget.value : ''
    this.close()
    const url = this.redirectUrlValue + (email ? '?email=' + encodeURIComponent(email) : '')
    window.location.href = url
  }
}
