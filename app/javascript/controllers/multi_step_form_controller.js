import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progress", "progressBar", "nextButton", "submitButton", "previousButton"]

  connect() {
    this.currentStep = 0
    this.showCurrentStep()
  }

  next(event) {
    event.preventDefault()
    if (this.validateCurrentStep()) {
      this.currentStep++
      this.showCurrentStep()
    }
  }

  previous(event) {
    event.preventDefault()
    if (this.currentStep > 0) {
      this.currentStep--
      this.showCurrentStep()
    }
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
    const isFirstStep = this.currentStep === 0
    const isLastStep = this.currentStep === this.stepTargets.length - 1

    if (this.hasPreviousButtonTarget) {
        this.previousButtonTarget.classList.toggle("hidden", isFirstStep)
    }

    if (this.hasNextButtonTarget) {
        this.nextButtonTarget.classList.toggle("hidden", isLastStep)
    }

    if (this.hasSubmitButtonTarget) {
        const canSubmit = isLastStep && this.isFormValid()
        this.submitButtonTarget.classList.toggle("hidden", !canSubmit)
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

    inputs.forEach(input => {
      if (!input.checkValidity()) {
        input.reportValidity()
        isValid = false
      }
    })

    // Check checkboxes if required
    const checkboxGroups = currentStepElement.querySelectorAll('.checkbox-group[data-required="true"]')
    checkboxGroups.forEach(group => {
       const checkedBoxes = group.querySelectorAll('input[type="checkbox"]:checked, input[type="radio"]:checked')
       if (checkedBoxes.length === 0) {
           isValid = false
           // Add a brutalist error feedback
           group.classList.add('border-2', 'border-red-500', 'p-4', 'shadow-[6px_6px_0px_0px_#ef4444]')
           setTimeout(() => group.classList.remove('border-2', 'border-red-500', 'p-4', 'shadow-[6px_6px_0px_0px_#ef4444]'), 2000)
       }
    })

    return isValid
  }
}
