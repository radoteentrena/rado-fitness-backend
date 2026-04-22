import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["generateButton"]

  handleSubmit(e) {
    const button = this.generateButtonTarget

    // Add loading class
    button.classList.add("loading")
    button.disabled = true

    // Store original content
    const icon = button.querySelector('.generate-icon')
    const text = button.querySelector('.generate-text')

    if (icon && text) {
      // Hide text
      text.style.display = 'none'

      // Add spinner animation to icon
      icon.style.animation = 'spin 1s linear infinite'

      // Add "Generando..." text
      const span = document.createElement('span')
      span.textContent = 'Generando...'
      span.style.marginLeft = '0.5rem'
      span.className = 'generating-text'
      button.appendChild(span)
    }

    // Reduce button opacity
    button.style.opacity = '0.8'
    button.style.pointerEvents = 'none'
  }
}

// Add keyframe animation
const style = document.createElement('style')
style.textContent = `
  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
`
document.head.appendChild(style)
