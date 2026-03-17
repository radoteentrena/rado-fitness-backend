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

    if (this.hasPreviousButtonTarget) {
        this.previousButtonTarget.classList.remove("hidden")
    }

    if (this.hasNextButtonTarget) {
        this.nextButtonTarget.classList.toggle("hidden", isLastStep)
    }

    if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.classList.toggle("hidden", !isLastStep)
    }
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
              // Here, ANY checkbox change in the group should remove errors from ALL checkboxes in the group
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
