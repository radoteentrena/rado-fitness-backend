import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "calendarGrid", "monthLabel", "prevButton",
    "slotsPanel", "scheduledAtInput", "confirmButton", "form"
  ]

  connect() {
    this.availableDates = new Set(JSON.parse(this.element.dataset.availableDates || "[]"))
    const today = new Date()
    this.displayYear   = today.getFullYear()
    this.displayMonth  = today.getMonth()
    this.todayMidnight = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    this.selectedDayEl = null
    this.renderCalendar()
  }

  prevMonth() {
    const now = new Date()
    if (this.displayYear === now.getFullYear() && this.displayMonth === now.getMonth()) return
    if (this.displayMonth === 0) { this.displayMonth = 11; this.displayYear-- }
    else { this.displayMonth-- }
    this.renderCalendar()
  }

  nextMonth() {
    if (this.displayMonth === 11) { this.displayMonth = 0; this.displayYear++ }
    else { this.displayMonth++ }
    this.renderCalendar()
  }

  renderCalendar() {
    const MONTHS = ["Enero","Febrero","Marzo","Abril","Mayo","Junio",
                    "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"]
    this.monthLabelTarget.textContent = `${MONTHS[this.displayMonth]} ${this.displayYear}`

    const now = new Date()
    this.prevButtonTarget.disabled =
      this.displayYear === now.getFullYear() && this.displayMonth === now.getMonth()

    const grid = this.calendarGridTarget
    grid.innerHTML = ""

    const firstDayOfWeek = new Date(this.displayYear, this.displayMonth, 1).getDay()
    const daysInMonth    = new Date(this.displayYear, this.displayMonth + 1, 0).getDate()

    for (let i = 0; i < firstDayOfWeek; i++) {
      grid.appendChild(document.createElement("div"))
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const date        = new Date(this.displayYear, this.displayMonth, day)
      const iso         = this.#isoDate(date)
      const isAvailable = this.availableDates.has(iso)
      const isPast      = date < this.todayMidnight

      const btn = document.createElement("button")
      btn.type = "button"
      btn.textContent = day

      if (isAvailable && !isPast) {
        btn.className = "w-full py-2 text-sm font-display font-bold border-2 border-white text-white hover:border-saffron hover:text-saffron transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-saffron"
        btn.dataset.date = iso
        btn.dataset.availabilityUrl = `/booking/availability?date=${iso}`
        btn.addEventListener("click", (e) => this.#selectDay(e))
      } else {
        btn.className = "w-full py-2 text-sm text-gray-700 cursor-default"
        btn.disabled = true
      }

      grid.appendChild(btn)
    }
  }

  #selectDay(event) {
    const btn = event.currentTarget

    if (this.selectedDayEl && this.selectedDayEl !== btn) {
      this.selectedDayEl.className = "w-full py-2 text-sm font-display font-bold border-2 border-white text-white hover:border-saffron hover:text-saffron transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-saffron"
    }
    btn.className = "w-full py-2 text-sm font-display font-bold border-2 border-saffron bg-saffron text-black shadow-[4px_4px_0px_0px_#ffffff] focus:outline-none"
    this.selectedDayEl = btn

    this.confirmButtonTarget.classList.add("hidden")
    this.scheduledAtInputTarget.value = ""

    this.slotsPanelTarget.innerHTML = `
      <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-6">Horarios disponibles</p>
      <p class="text-gray-500 text-sm">Cargando…</p>
    `

    fetch(btn.dataset.availabilityUrl, {
      headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
    })
      .then(r => r.json())
      .then(data => this.#renderSlots(data.slots || [], btn.dataset.date))
      .catch(() => {
        this.slotsPanelTarget.innerHTML = `
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-6">Horarios disponibles</p>
          <p class="text-red-400 text-sm">Error al cargar horarios.</p>
        `
      })
  }

  #renderSlots(slots, date) {
    const panel = this.slotsPanelTarget

    if (slots.length === 0) {
      panel.innerHTML = `
        <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-6">Horarios disponibles</p>
        <p class="text-gray-500 text-sm">No hay horarios disponibles para este día.</p>
      `
      return
    }

    panel.innerHTML = `
      <p class="text-xs font-bold uppercase tracking-widest text-gray-400 mb-6">Horarios disponibles</p>
      <div class="space-y-2">
        ${slots.map(time => `
          <button type="button"
            class="slot-btn w-full border-2 border-white px-4 py-3 text-sm font-display font-bold text-white hover:border-saffron hover:text-saffron transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-saffron"
            data-datetime="${date}T${time}:00">
            ${time}
          </button>
        `).join("")}
      </div>
    `

    panel.querySelectorAll(".slot-btn").forEach(b => {
      b.addEventListener("click", (e) => this.#selectSlot(e))
    })
  }

  #selectSlot(event) {
    const btn = event.currentTarget

    this.slotsPanelTarget.querySelectorAll(".slot-btn").forEach(b => {
      b.className = "slot-btn w-full border-2 border-white px-4 py-3 text-sm font-display font-bold text-white hover:border-saffron hover:text-saffron transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-saffron"
    })
    btn.className = "slot-btn w-full border-2 border-saffron bg-saffron px-4 py-3 text-sm font-display font-bold text-black shadow-[4px_4px_0px_0px_#ffffff] focus:outline-none"

    this.scheduledAtInputTarget.value = btn.dataset.datetime
    this.confirmButtonTarget.classList.remove("hidden")
  }

  #isoDate(date) {
    return [
      date.getFullYear(),
      String(date.getMonth() + 1).padStart(2, "0"),
      String(date.getDate()).padStart(2, "0")
    ].join("-")
  }
}
