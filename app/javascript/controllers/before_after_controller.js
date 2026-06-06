import { Controller } from "@hotwired/stimulus"

const CLIENTS = [
  {
    name: "Martu", ig: "@martuojedax",
    title: "De gymbro a afiliada de Gymshark",
    sub: "Este cambio fue sentarme con ella y explicarle la teoría de cómo cambiar la composición corporal. Ponerle un orden de importancia a la información y juntos crear un plan que se ajustó a su estilo de vida.",
    metrics: [
      {label: "Peso", before: "61kg", after: "52kg"},
      {label: "Grasa corp.", before: "24%", after: "18%"},
    ],
  },
  {
    name: "Luis", ig: "@luis_povina",
    title: "Perdió 25kg de grasa",
    sub: "Luego de aprender la teoría, logramos aplicar conceptos que, en solo 8 meses de seguimiento personalizado, logramos transformar su físico y su vida.",
    metrics: [
      {label: "Peso", before: "118kg", after: "87kg"},
      {label: "Grasa corp.", before: "35%", after: "14%"},
    ],
  },
  {
    name: "Cami", ig: "@camiocampob",
    title: "Cambió su físico comiendo más",
    sub: "Después de varios intentos de dietas estrictas y frustraciones, nos sentamos a repasar la teoría de la nutrición y a través de la confianza depositada en mi método, logró comer más y verse mejor.",
    metrics: [
      {label: "Peso", before: "60kg", after: "60kg"},
      {label: "Grasa corp.", before: "27%", after: "22%"},
    ],
  },
  {
    name: "Cheky", ig: "@checkz_",
    title: "Plan llegar al verano",
    sub: "Acá el objetivo estaba claro, bajar el porcentaje de grasa para verse mejor en una fecha específica. En sólo tres meses el plan fue ejecutado a la perfección.",
    metrics: [
      {label: "Peso", before: "68kg", after: "63kg"},
      {label: "Grasa corp.", before: "18%", after: "10%"},
    ],
  },
    {
    name: "Benja", ig: "@benjaz",
    title: "Transformación de composición corporal en 8 meses",
    sub: "Este cambio se basó en un deficit calórico sostenido, enfocado en preservar y mejorar su masa muscular.",
    metrics: [
      {label: "Peso", before: "106kg", after: "82kg"},
      {label: "Grasa corp.", before: "32%", after: "16%"},
    ],
  },
  {
    name: "Fede", ig: "@fedearga92",
    title: "Caso de éxito en 3 años",
    sub: "Hábitos inteligentes para mantenerse motivado, con un entrenamiento y plan de nutrición acorde a su estilo de vida. No para de ponerla.",
    metrics: [
      {label: "Peso", before: "90kg", after: "68kg"},
      {label: "Grasa corp.", before: "30%", after: "18%"},
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
  static values = { index: { type: Number, default: 0 }, images: Array }

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
    const imgs = this.imagesValue[this.indexValue] || {}
    this.imgBeforeTarget.src = imgs.before || ""
    this.imgAfterTarget.src  = imgs.after  || ""
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
