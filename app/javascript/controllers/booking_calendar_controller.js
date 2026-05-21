import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dayButton", "slotsPanel", "scheduledAtInput", "confirmButton", "form"]

  selectDay(event) {
    const button = event.currentTarget
    const date = button.dataset.date
    const url = button.dataset.availabilityUrl

    this.dayButtonTargets.forEach(btn => {
      btn.classList.remove("bg-saffron", "text-black", "shadow-[4px_4px_0px_0px_#ffffff]")
      btn.classList.add("border-white")
    })
    button.classList.add("bg-saffron", "text-black", "shadow-[4px_4px_0px_0px_#ffffff]")
    button.classList.remove("border-white")

    this.slotsPanelTarget.innerHTML = `
      <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-6">Horarios disponibles</p>
      <p class="text-gray-500 text-sm">Cargando...</p>
    `
    this.confirmButtonTarget.classList.add("hidden")

    fetch(url, {
      headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
    })
      .then(r => r.json())
      .then(data => this.renderSlots(date, data.slots || []))
      .catch(() => {
        this.slotsPanelTarget.innerHTML = `
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-6">Horarios disponibles</p>
          <p class="text-red-400 text-sm">Error al cargar horarios.</p>
        `
      })
  }

  renderSlots(date, slots) {
    if (slots.length === 0) {
      this.slotsPanelTarget.innerHTML = `
        <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-6">Horarios disponibles</p>
        <p class="text-gray-500 text-sm">No hay horarios disponibles para este día.</p>
      `
      return
    }

    const header = `<p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-6">Horarios disponibles</p>`
    const buttons = slots.map(time => `
      <button type="button"
        class="slot-btn w-full border-2 border-white px-4 py-3 text-left font-display font-bold text-sm uppercase tracking-wide hover:border-saffron transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-saffron mb-2"
        data-datetime="${date}T${time}:00"
        data-action="click->booking-calendar#selectSlot">
        ${time}
      </button>
    `).join("")

    this.slotsPanelTarget.innerHTML = header + buttons
  }

  selectSlot(event) {
    const button = event.currentTarget
    const datetime = button.dataset.datetime

    this.slotsPanelTarget.querySelectorAll(".slot-btn").forEach(btn => {
      btn.classList.remove("bg-saffron", "text-black", "shadow-[4px_4px_0px_0px_#ffffff]")
      btn.classList.add("border-white")
    })
    button.classList.add("bg-saffron", "text-black", "shadow-[4px_4px_0px_0px_#ffffff]")
    button.classList.remove("border-white")

    this.scheduledAtInputTarget.value = datetime
    this.confirmButtonTarget.classList.remove("hidden")
  }
}
