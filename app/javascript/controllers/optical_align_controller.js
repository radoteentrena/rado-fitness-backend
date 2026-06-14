import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._handler = () => this.apply()

    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(this._handler)
    } else {
      document.addEventListener('DOMContentLoaded', this._handler)
    }

    window.addEventListener('resize', this._handler)
  }

  disconnect() {
    window.removeEventListener('resize', this._handler)
  }

  apply() {
    const cvs = document.createElement('canvas')
    const ctx = cvs.getContext('2d')

    document.querySelectorAll('.optical-align').forEach(el => {
      el.style.marginLeft = '0px'
      const cs = getComputedStyle(el)
      const ch = (el.textContent || '').trim()[0]
      if (!ch) return
      const char = cs.textTransform === 'uppercase' ? ch.toUpperCase() : ch
      ctx.font = `${cs.fontStyle} ${cs.fontWeight} ${cs.fontSize} ${cs.fontFamily}`
      ctx.textAlign = 'left'
      const abl = ctx.measureText(char).actualBoundingBoxLeft
      if (isFinite(abl) && abl > 0) el.style.marginLeft = `${abl.toFixed(2)}px`
    })
  }
}
