import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { start: String }

  connect() {
    this.renderTime()
    this.interval = window.setInterval(() => this.renderTime(), 1000)
  }

  disconnect() {
    window.clearInterval(this.interval)
  }

  renderTime() {
    const elapsed = Math.max(0, Math.round((Date.now() - Date.parse(this.startValue)) / 1000))
    const hours = Math.floor(elapsed / 3600)
    const minutes = Math.floor(elapsed / 60) % 60
    const seconds = String(elapsed % 60).padStart(2, "0")
    this.element.textContent = hours ? `${hours}:${String(minutes).padStart(2, "0")}:${seconds}` : `${minutes}:${seconds}`
  }
}
