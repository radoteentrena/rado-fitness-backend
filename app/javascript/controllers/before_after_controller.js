import { Controller } from "@hotwired/stimulus"

const CLIENTS = [
  {
    name: "Marcos Reyes", ig: "@marcos.lifts",
    title: "Perdió 25 kg sin dejar de comer",
    sub: "Profesional ocupado que retomó el control de su cuerpo.",
    before: "/assets/testimonial_1.png", after: "/assets/testimonial_2.png",
    metrics: [
      { label: "Peso",        before: "105 kg",  after: "80 kg"  },
      { label: "Grasa corp.", before: "31%",     after: "14%"    },
      { label: "Masa muscular",  before: "60 kg",   after: "130 kg" },
    ],
  },
  {
    name: "Sofía Herrera", ig: "@sofia.strong",
    title: "Fuerza real después de dos embarazos",
    sub: "Recuperó su cuerpo —y su confianza— en 8 meses.",
    before: "/assets/testimonial_3.png", after: "/assets/testimonial_4.png",
    metrics: [
      { label: "Peso muerto", before: "40 kg",  after: "100 kg" },
      { label: "Grasa corp.", before: "31%",     after: "14%"    },
      { label: "Masa muscular",  before: "60 kg",   after: "130 kg" },
    ],
  },
  {
    name: "Diego Torres", ig: "@diego.builds",
    title: "De flaco a listo para el escenario",
    sub: "Doce meses de hipertrofia disciplinada con Rado.",
    before: "/assets/testimonial_1.png", after: "/assets/testimonial_3.png",
    metrics: [
      { label: "Peso",        before: "65 kg",  after: "83 kg"  },
      { label: "Grasa corp.", before: "31%",     after: "14%"    },
      { label: "Masa muscular",  before: "60 kg",   after: "130 kg" },
    ],
  },
]

export default class extends Controller {
  static targets = [
    "storyTitle", "storySub", "metricBody",
    "clientName", "clientIg",
    "imgBefore", "imgAfter",
    "dots"
  ]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.buildDots()
    this.paint()

    this._onKeyDown = this._handleKey.bind(this)
    document.addEventListener("keydown", this._onKeyDown)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeyDown)
  }

  next() { this.go(this.indexValue + 1) }
  prev() { this.go(this.indexValue - 1) }
  goTo(event) { this.go(parseInt(event.currentTarget.dataset.idx)) }

  go(idx) {
    const n = CLIENTS.length
    const next = ((idx % n) + n) % n
    const fadeEls = [
      this.storyTitleTarget, this.storySubTarget, this.metricBodyTarget,
      this.clientNameTarget, this.clientIgTarget,
    ]
    fadeEls.forEach(el => { el.style.opacity = "0"; el.style.transition = "opacity .28s ease" })
    setTimeout(() => {
      this.indexValue = next
      this.paint()
      fadeEls.forEach(el => { el.style.opacity = "1" })
    }, 240)
  }

  paint() {
    const c = CLIENTS[this.indexValue]
    this.clientNameTarget.textContent = c.name
    this.clientIgTarget.textContent   = c.ig
    this.storyTitleTarget.textContent = c.title
    this.storySubTarget.textContent   = c.sub
    this.imgBeforeTarget.src = c.before
    this.imgAfterTarget.src  = c.after
    this.metricBodyTarget.innerHTML = c.metrics.map(m =>
      `<tr>
        <td class="text-left font-medium text-white py-[18px] border-t border-white/10 text-[17px]">${m.label}</td>
        <td class="text-right text-[#cfcfcf] py-[18px] border-t border-white/10 text-[17px]">${m.before}</td>
        <td class="text-right font-bold text-saffron py-[18px] border-t border-white/10 text-[17px]">${m.after}</td>
      </tr>`
    ).join("")
    this.dotsTarget.querySelectorAll("button").forEach((dot, i) => {
      dot.style.width      = i === this.indexValue ? "22px" : "8px"
      dot.style.borderRadius = i === this.indexValue ? "99px" : "50%"
      dot.style.background = i === this.indexValue ? "#F5C228" : "rgba(255,255,255,0.22)"
    })
  }

  buildDots() {
    this.dotsTarget.innerHTML = CLIENTS.map((_, idx) =>
      `<button
        data-action="click->before-after#goTo"
        data-idx="${idx}"
        aria-label="Cliente ${idx + 1}"
        style="width:8px;height:8px;border-radius:50%;border:0;padding:0;background:rgba(255,255,255,0.22);cursor:pointer;transition:all .25s ease;"
      ></button>`
    ).join("")
  }

  _handleKey(e) {
    if (e.key === "ArrowLeft")  this.prev()
    if (e.key === "ArrowRight") this.next()
  }
}
