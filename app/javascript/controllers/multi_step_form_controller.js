import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progress", "progressBar", "nextButton", "submitButton", "previousButton", "phoneField", "phonePrefixSelect", "phoneNumberInput"]

  connect() {
    this.storageKey = `multi-step-form-${window.location.pathname}`
    const savedStep = sessionStorage.getItem(this.storageKey)
    this.currentStep = savedStep ? parseInt(savedStep, 10) : 0

    if (this.currentStep >= this.stepTargets.length) {
      this.currentStep = 0
    }

    this.showCurrentStep()
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    if (event.key === "Enter" && event.target.tagName !== "TEXTAREA") {
      event.preventDefault()
    }
  }

  async next(event) {
    event.preventDefault()
    if (this.currentStep >= this.stepTargets.length - 1) return
    if (!this.validateCurrentStep()) return

    const emailInput = this.stepTargets[this.currentStep].querySelector('input[data-email-check="true"]')
    if (emailInput) {
      const exists = await this.checkEmailExists(emailInput.value)
      if (exists) {
        window.location.href = `/onboarding/email_exists?email=${encodeURIComponent(emailInput.value)}`
        return
      }
    }

    this.currentStep++
    this.saveStep()
    this.showCurrentStep()
    window.scrollTo({ top: 0, behavior: "smooth" })
  }

  previous(event) {
    event.preventDefault()
    if (this.currentStep === 0) {
      window.location.href = "/"
      return
    }
    this.currentStep--
    this.saveStep()
    this.showCurrentStep()
    window.scrollTo({ top: 0, behavior: "smooth" })
  }

  async checkEmailExists(email) {
    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch("/onboarding/check_email", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
        body: JSON.stringify({ email })
      })
      const data = await response.json()
      return data.exists
    } catch {
      return false
    }
  }

  syncPhone() {
    const prefix = this.hasPhonePrefixSelectTarget ? this.phonePrefixSelectTarget.value : ""
    const number = this.hasPhoneNumberInputTarget ? this.phoneNumberInputTarget.value.trim() : ""
    if (this.hasPhoneFieldTarget) {
      this.phoneFieldTarget.value = `${prefix}${number}`
    }
  }

  filterSelect(event) {
    const query = event.target.value.toLowerCase()
    const targetId = event.target.dataset.targetSelect
    const select = document.getElementById(targetId)
    if (!select) return

    let firstVisible = null
    Array.from(select.options).forEach(option => {
      const matches = option.text.toLowerCase().includes(query)
      option.hidden = !matches
      if (matches && !firstVisible) firstVisible = option
    })
  }

  showCurrentStep() {
    this.stepTargets.forEach((target, index) => {
      target.classList.toggle("hidden", index !== this.currentStep)
    })

    this.updateProgress()
    this.updateButtons()
  }

  updateProgress() {
    const totalSteps = this.stepTargets.length
    const progressPercentage = ((this.currentStep + 1) / totalSteps) * 100

    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${progressPercentage}%`
    }

    if (this.hasProgressTarget) {
      this.progressTarget.textContent = `Paso ${this.currentStep + 1} de ${totalSteps}`
    }
  }

  updateButtons() {
    const isLastStep = this.currentStep === this.stepTargets.length - 1

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.style.display = isLastStep ? "none" : ""
    }

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.classList.toggle("hidden", !isLastStep)
    }
  }

  // Generic conditional toggle: driven by data-condition-target and data-condition-values on the input
  toggleConditional(event) {
    const input = event.target
    const targetId = input.dataset.conditionTarget
    if (!targetId) return

    const showValues = (input.dataset.conditionValues || "").split(",").map(v => v.trim())
    const targetEl = document.getElementById(targetId)
    if (!targetEl) return

    let selectedValue = ""
    if (input.type === "radio") {
      const checked = input.closest("form").querySelector(`input[name="${input.name}"]:checked`)
      selectedValue = checked ? checked.value : ""
    } else if (input.type === "checkbox") {
      const checked = input.closest(".checkbox-group")?.querySelector('input[type="checkbox"]:checked')
      selectedValue = checked ? checked.value : ""
    }

    const shouldShow = showValues.includes(selectedValue)
    targetEl.classList.toggle("hidden", !shouldShow)

    // Clear required on hidden fields and restore on visible
    targetEl.querySelectorAll("input, select, textarea").forEach(el => {
      if (el.dataset.conditionalRequired) {
        el.required = shouldShow
      }
    })
  }

  toggleBestLifts(event) {
    const selected = event.target.closest("form").querySelector('input[name="user[onboarding_profile_attributes][training_years]"]:checked')
    const show = selected && ["2-5", "5+"].includes(selected.value)
    document.getElementById("best-lifts-container")?.classList.toggle("hidden", !show)
  }

  toggleSportDetails(event) {
    const show = event.target.value === "Si"
    document.getElementById("sport-details-container")?.classList.toggle("hidden", !show)
  }

  toggleReferralOther(event) {
    const show = event.target.value === "Otro"
    const container = document.getElementById("referral-other-container")
    if (!container) return
    container.classList.toggle("hidden", !show)
    const input = container.querySelector("input")
    if (input) input.required = show
  }

  toggleGoalsOther(event) {
    const checked = event.target.checked
    const container = document.getElementById("goals-other-container")
    if (!container) return
    container.classList.toggle("hidden", !checked)
    const input = container.querySelector("input")
    if (input) input.required = checked
  }

  isFormValid() {
    let isValid = true

    this.stepTargets.forEach(step => {
      const inputs = step.querySelectorAll("input[required], select[required], textarea[required]")
      inputs.forEach(input => {
        if (!input.checkValidity()) {
          isValid = false
        }
      })

      const checkboxGroups = step.querySelectorAll('.checkbox-group[data-required="true"]')
      checkboxGroups.forEach(group => {
         const checkedBoxes = group.querySelectorAll('input[type="checkbox"]:checked, input[type="radio"]:checked')
         if (checkedBoxes.length === 0) {
             isValid = false
         }
      })
    })

    return isValid
  }

  validateCurrentStep() {
    const { valid, firstInvalidInput } = this.validateStep(this.stepTargets[this.currentStep])
    if (firstInvalidInput) firstInvalidInput.focus()
    return valid
  }

  // Validate every step before allowing the final submit. If anything required
  // is missing, block submission and jump to the first incomplete step.
  validateForm(event) {
    let firstInvalidStep = null

    this.stepTargets.forEach((step, index) => {
      const { valid } = this.validateStep(step)
      if (!valid && firstInvalidStep === null) firstInvalidStep = index
    })

    if (firstInvalidStep !== null) {
      event.preventDefault()
      this.currentStep = firstInvalidStep
      this.saveStep()
      this.showCurrentStep()
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  validateStep(currentStepElement) {
    const inputs = currentStepElement.querySelectorAll("input[required], select[required], textarea[required]")
    let isValid = true
    let firstInvalidInput = null

    const addErrorStyling = (errorTarget, triggers) => {
      if (errorTarget.classList.contains('border-primary/50')) {
        errorTarget.classList.remove('border-primary/50')
        errorTarget.dataset.hadPrimaryBorder = 'true'
      }
      errorTarget.classList.add('border-red-500', 'shadow-[6px_6px_0px_0px_#ef4444]')

      const removeError = () => {
        errorTarget.classList.remove('border-red-500', 'shadow-[6px_6px_0px_0px_#ef4444]')
        if (errorTarget.dataset.hadPrimaryBorder === 'true') {
          errorTarget.classList.add('border-primary/50')
          delete errorTarget.dataset.hadPrimaryBorder
        }
      }

      triggers.forEach(trigger => {
        trigger.addEventListener('input', removeError, { once: true })
        trigger.addEventListener('change', removeError, { once: true })
      })
    }

    // Spanish reason derived from the field's validity state
    const messageFor = (input) => {
      const v = input.validity
      if (v.valueMissing) {
        return (input.type === 'radio' || input.type === 'checkbox') ? 'Seleccioná una opción' : 'Este campo es obligatorio'
      }
      if (input.type === 'email' && (v.typeMismatch || v.patternMismatch)) return 'Ingresá un correo electrónico válido'
      if (v.rangeUnderflow || v.rangeOverflow || v.badInput || v.stepMismatch) return 'Ingresá un valor válido'
      if (v.tooLong) return 'El texto es demasiado largo'
      if (v.patternMismatch && input.type === 'tel') return 'Ingresá solo números'
      if (v.patternMismatch) return 'El formato no es válido'
      return 'Revisá este campo'
    }

    // Insert (or update) the red message right after the field block.
    // Inline styles so it never depends on Tailwind scanning this JS file.
    const showFieldError = (anchorEl, message, triggers) => {
      const existing = anchorEl.nextElementSibling
      if (existing && existing.classList.contains('field-error')) {
        existing.textContent = message
        return
      }
      const p = document.createElement('p')
      p.className = 'field-error'
      p.textContent = message
      p.style.cssText = 'margin-top:0.75rem;font-size:0.875rem;font-weight:700;color:#ef4444;text-transform:uppercase;letter-spacing:0.05em;'
      anchorEl.insertAdjacentElement('afterend', p)

      const removeMessage = () => p.remove()
      triggers.forEach(trigger => {
        trigger.addEventListener('input', removeMessage, { once: true })
        trigger.addEventListener('change', removeMessage, { once: true })
      })
    }

    inputs.forEach(input => {
      // Skip inputs inside hidden conditional containers
      if (input.closest('.conditional-field.hidden')) return

      if (!input.checkValidity()) {
        if (!firstInvalidInput) firstInvalidInput = input

        let errorTarget = input
        let triggers = [input]

        if (input.type === 'radio' || input.type === 'checkbox') {
          const wrapperLabel = input.closest('label')
          if (wrapperLabel && wrapperLabel.classList.contains('border-2')) {
            errorTarget = wrapperLabel
          }
          if (input.type === 'radio') {
            triggers = Array.from(input.closest('form').querySelectorAll(`input[name="${input.name}"]`))
          }
        }

        addErrorStyling(errorTarget, triggers)

        // One message per field (radio groups: anchor after the options container)
        if (input.type === 'radio') {
          const groupAnchor = input.closest('.space-y-4') || errorTarget
          showFieldError(groupAnchor, messageFor(input), triggers)
        } else {
          // Anchor after the input, or after its immediate flex wrapper (e.g. phone)
          const parent = input.parentElement
          const anchor = parent && parent.classList.contains('flex') ? parent : input
          showFieldError(anchor, messageFor(input), triggers)
        }

        isValid = false
      }
    })

    // Check custom checkbox groups if required
    const checkboxGroups = currentStepElement.querySelectorAll('.checkbox-group[data-required="true"]')
    checkboxGroups.forEach(group => {
       const checkboxes = Array.from(group.querySelectorAll('input[type="checkbox"], input[type="radio"]'))
       const checkedBoxes = checkboxes.filter(cb => cb.checked)
       if (checkedBoxes.length === 0) {
           isValid = false
           if (!firstInvalidInput && checkboxes.length > 0) firstInvalidInput = checkboxes[0]

           checkboxes.forEach(cb => {
              let errorTarget = cb
              const wrapperLabel = cb.closest('label')
              if (wrapperLabel && wrapperLabel.classList.contains('border-2')) {
                errorTarget = wrapperLabel
              }
              addErrorStyling(errorTarget, checkboxes)
           })
           showFieldError(group, 'Seleccioná al menos una opción', checkboxes)
       }
    })

    // Check searchable-select fields (hidden input must have a value)
    const searchableSelects = currentStepElement.querySelectorAll('[data-searchable-select-target="hidden"]')
    searchableSelects.forEach(hidden => {
      if (!hidden.value) {
        isValid = false
        const container = hidden.closest('[data-controller="searchable-select"]')
        const textInput = container?.querySelector('[data-searchable-select-target="input"]')
        if (textInput) {
          if (!firstInvalidInput) firstInvalidInput = textInput
          addErrorStyling(textInput, [textInput])
          const options = Array.from(container.querySelectorAll('[data-searchable-select-target="option"]'))
          showFieldError(container, 'Seleccioná una opción', [textInput, ...options])
        }
      }
    })

    return { valid: isValid, firstInvalidInput }
  }

  saveStep() {
    sessionStorage.setItem(this.storageKey, this.currentStep)
  }
}
