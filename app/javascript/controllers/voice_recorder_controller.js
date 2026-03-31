import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["voiceInput", "waveform", "status"]

  connect() {
    this.mediaRecorder = null
    this.audioChunks = []
    this.isRecording = false
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

        this.mediaRecorder.start()
        this.isRecording = true
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
      this.updateUI('saved')
      this.updateStatus('✓ Mensaje de voz grabado')
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
    const waveform = this.waveformTarget

    if (state === 'recording') {
      recordBtn.classList.add('hidden')
      stopBtn.classList.remove('hidden')
      waveform.classList.remove('hidden')
    } else if (state === 'saved') {
      recordBtn.classList.remove('hidden')
      stopBtn.classList.add('hidden')
      waveform.classList.add('hidden')
    }
  }

  updateStatus(message) {
    this.statusTarget.textContent = message
  }
}
