import { Controller } from "@hotwired/stimulus"

// Attached once to the shared <dialog>. Listens for the window "admin:confirm"
// event, opens itself, and submits a full-page DELETE on confirm.
export default class extends Controller {
  static targets = ["dialog", "title", "message", "warning", "submit", "confirmFooter", "blockFooter"]

  connect() {
    this.open = this.open.bind(this)
    this.reset = this.reset.bind(this)
    window.addEventListener("admin:confirm", this.open)
    document.addEventListener("turbo:before-visit", this.reset)
    document.addEventListener("turbo:frame-load", this.handleFrameLoad)
    this.dialogTarget.addEventListener("close", this.reset)
  }

  disconnect() {
    window.removeEventListener("admin:confirm", this.open)
    document.removeEventListener("turbo:before-visit", this.reset)
    document.removeEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  open(event) {
    const { title, message, mode, href } = event.detail
    this.pendingHref = href
    this.titleTarget.textContent = title

    if (message) {
      this.warningTarget.textContent = message
      this.warningTarget.classList.remove("hidden")
      this.messageTarget.classList.add("hidden")
    } else {
      this.warningTarget.classList.add("hidden")
      this.messageTarget.classList.remove("hidden")
    }

    const blocked = mode === "block"
    this.confirmFooterTarget.classList.toggle("hidden", blocked)
    this.blockFooterTarget.classList.toggle("hidden", !blocked)

    this.dialogTarget.showModal()
  }

  cancel() {
    this.dialogTarget.close()
  }

  confirm() {
    this.submitTarget.disabled = true

    const form = document.createElement("form")
    form.method = "post"
    form.action = this.pendingHref
    form.appendChild(this.hiddenInput("_method", "delete"))
    form.appendChild(this.hiddenInput("authenticity_token", this.csrfToken()))
    document.body.appendChild(form)

    form.addEventListener("turbo:submit-start", () => form.remove(), { once: true })
    form.addEventListener("turbo:submit-end", (e) => {
      if (!e.detail.success) this.reenableSubmit()
    }, { once: true })
    form.addEventListener("turbo:fetch-request-error", () => this.reenableSubmit(), { once: true })

    this.dialogTarget.close()
    form.requestSubmit()
  }

  reset() {
    this.titleTarget.textContent = ""
    this.warningTarget.textContent = ""
    this.warningTarget.classList.add("hidden")
    this.reenableSubmit()
  }

  handleFrameLoad = (event) => {
    if (event.target.id === "admin_main_content") this.reset()
  }

  reenableSubmit() {
    this.submitTarget.disabled = false
  }

  hiddenInput(name, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    return input
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
