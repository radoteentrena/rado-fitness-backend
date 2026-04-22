import { Controller } from "@hotwired/stimulus"

const MAX_RECORDING_TIME = 300000 // 5 minutes in milliseconds

export default class extends Controller {
  static targets = ["voiceInput", "waveform", "status"]

  connect() {
    this.mediaRecorder = null
    this.audioChunks = []
    this.isRecording = false
    this.recordingStartTime = null
    this.timerInterval = null
  }

  start(event) {
    event.preventDefault()
    this.audioChunks = []

    navigator.mediaDevices.getUserMedia({ audio: true })
      .then(stream => {
        this.mediaRecorder = new MediaRecorder(stream)

        this.mediaRecorder.ondataavailable = (event) => {
          this.audioChunks.push(event.data)
        }

        this.mediaRecorder.onstop = () => {
          const audioBlob = new Blob(this.audioChunks, { type: "audio/webm" })
          this.saveAudio(audioBlob)
          stream.getTracks().forEach(track => track.stop())
        }

        this.mediaRecorder.onerror = (event) => {
          this.updateStatus(`Error: ${event.error}`)
          this.isRecording = false
          this.stopTimer()
          this.updateUI('saved')
        }

        this.mediaRecorder.start()
        this.isRecording = true
        this.recordingStartTime = Date.now()
        this.startTimer()
        this.updateUI('recording')
      })
      .catch(err => {
        this.updateStatus(`Error: ${err.message}`)
      })
  }

  stop(event) {
    event.preventDefault()
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.isRecording = false
      this.stopTimer()
      this.updateUI('saved')
      this.updateStatus('✓ Mensaje de voz grabado')
    }
  }

  toggleRecording(event) {
    event.preventDefault()
    if (this.isRecording) {
      this.stop(event)
    } else {
      this.start(event)
    }
  }

  startTimer() {
    this.timerInterval = setInterval(() => {
      if (this.isRecording && this.recordingStartTime) {
        const elapsed = Date.now() - this.recordingStartTime

        // Auto-stop at max recording time
        if (elapsed >= MAX_RECORDING_TIME) {
          this.stop({ preventDefault: () => {} })
          this.updateStatus('⏱ Tiempo máximo alcanzado')
          return
        }

        const elapsedSeconds = Math.floor(elapsed / 1000)
        const minutes = Math.floor(elapsedSeconds / 60)
        const seconds = elapsedSeconds % 60
        const timeString = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
        this.updateStatus(timeString)
      }
    }, 100)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  saveAudio(audioBlob) {
    const reader = new FileReader()
    reader.onloadend = () => {
      this.voiceInputTarget.value = reader.result
    }
    reader.readAsDataURL(audioBlob)
  }

  updateUI(state) {
    const recordBtn = this.element.querySelector(".btn-record")
    const stopBtn = this.element.querySelector(".btn-stop")

    // Check if waveform target exists (for legacy UI)
    const waveform = this.hasWaveformTarget ? this.waveformTarget : null

    if (state === 'recording') {
      if (recordBtn) recordBtn.classList.add('hidden')
      if (stopBtn) stopBtn.classList.remove('hidden')
      if (waveform) waveform.classList.remove('hidden')

      // Set data attribute for slim input style
      this.element.setAttribute('data-recording', 'true')

      // Trigger animation for status
      if (this.hasStatusTarget) {
        this.statusTarget.classList.remove('hidden')
        this.statusTarget.classList.add('recording-active')
      }
    } else if (state === 'saved') {
      if (recordBtn) recordBtn.classList.remove('hidden')
      if (stopBtn) stopBtn.classList.add('hidden')
      if (waveform) waveform.classList.add('hidden')

      // Remove data attribute
      this.element.setAttribute('data-recording', 'false')

      // Trigger animation for success message
      if (this.hasStatusTarget) {
        this.statusTarget.classList.remove('recording-active')
      }
    }
  }

  get hasWaveformTarget() {
    try {
      return this.waveformTargets.length > 0
    } catch {
      return false
    }
  }

  updateStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }
}
