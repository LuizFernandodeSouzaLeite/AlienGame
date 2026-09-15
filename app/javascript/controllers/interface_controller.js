import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["header", "dialog", "message"]

  connect() {
    this.abort = new AbortController()
    this.motion = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.previousScroll = window.scrollY
    window.addEventListener("scroll", () => {
      if (this.motion.matches) return
      const current = window.scrollY
      if (Math.abs(current - this.previousScroll) < 8) return
      this.headerTarget.classList.toggle("is-receding", current > 180 && current > this.previousScroll)
      this.previousScroll = current
    }, { passive: true, signal: this.abort.signal })
    document.addEventListener("turbo:before-cache", () => {
      this.headerTarget.classList.remove("is-receding")
      if (this.dialogTarget.open) this.dialogTarget.close("cancel")
    }, { signal: this.abort.signal })
    this.confirm = (message) => this.ask(message)
    Turbo.config.forms.confirm = this.confirm
    this.element.querySelector(".error-box")?.focus()
  }

  ask(message) {
    if (this.pending) return Promise.resolve(false)
    this.messageTarget.textContent = message
    this.opener = document.activeElement
    return new Promise((resolve) => {
      this.pending = resolve
      this.onClose = () => {
        const confirmed = this.dialogTarget.returnValue === "confirm"
        this.pending?.(confirmed)
        this.pending = null
        this.opener?.focus()
      }
      this.dialogTarget.returnValue = "cancel"
      this.dialogTarget.addEventListener("close", this.onClose, { once: true })
      this.dialogTarget.showModal()
    })
  }

  disconnect() {
    this.abort.abort()
    if (this.pending) {
      this.dialogTarget.removeEventListener("close", this.onClose)
      this.pending(false)
      this.pending = null
      this.dialogTarget.close("cancel")
    }
    if (Turbo.config.forms.confirm === this.confirm) Turbo.config.forms.confirm = (message) => Promise.resolve(window.confirm(message))
  }
}
