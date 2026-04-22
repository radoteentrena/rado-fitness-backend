import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progress", "progressBar", "nextButton", "submitButton", "previousButton"]

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

  next(event) {
    event.preventDefault()
    if (this.currentStep >= this.stepTargets.length - 1) return
    if (this.validateCurrentStep()) {
      this.currentStep++
      this.saveStep()
      this.showCurrentStep()
    }
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
    const currentStepElement = this.stepTargets[this.currentStep]
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
       }
    })

    if (firstInvalidInput) {
      firstInvalidInput.reportValidity()
    }

    return isValid
  }

  saveStep() {
    sessionStorage.setItem(this.storageKey, this.currentStep)
  }
}
