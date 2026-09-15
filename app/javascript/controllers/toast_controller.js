import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.resume()
    this.beforeCache = () => this.dismiss()
    document.addEventListener("turbo:before-cache", this.beforeCache)
  }
  resume() { this.pause(); this.timer = setTimeout(() => this.dismiss(), 8000) }
  pause() { clearTimeout(this.timer) }
  dismiss() { this.element.remove() }
  disconnect() { this.pause(); document.removeEventListener("turbo:before-cache", this.beforeCache) }
}
