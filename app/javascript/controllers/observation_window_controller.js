import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["port", "aperture", "button", "label"]

  connect() {
    this.open = false
    this.abort = new AbortController()
    const options = { signal: this.abort.signal }
    this.attachUniverse()
    window.addEventListener("resize", () => this.syncMask(), options)
    window.addEventListener("scroll", () => this.syncMask(), { ...options, passive: true })
    document.addEventListener("turbo:render", () => this.attachUniverseAndSync(), options)
    document.addEventListener("turbo:load", () => this.attachUniverseAndSync(), options)
    window.addEventListener("lab:camera-change", () => {
      this.syncMask()
      clearTimeout(this.cameraTimer)
      this.cameraTimer = setTimeout(() => this.syncMask(), 740)
    }, options)
    requestAnimationFrame(() => this.attachUniverseAndSync())
  }

  attachUniverse() {
    this.universe = document.getElementById("universe-engine")
    if (this.universe && this.universe.parentElement !== this.apertureTarget) this.apertureTarget.prepend(this.universe)
  }

  attachUniverseAndSync() {
    this.attachUniverse()
    this.syncMask()
  }

  toggle() {
    this.open = !this.open
    this.element.classList.toggle("is-open", this.open)
    this.buttonTarget.setAttribute("aria-expanded", this.open)
    this.labelTarget.textContent = this.open ? "CLOSE OBSERVATION PORT" : "OPEN OBSERVATION PORT"
    document.body.classList.toggle("observation-port-open", this.open)
    this.syncMask()
  }

  syncMask() {
    const rect = this.apertureTarget.getBoundingClientRect()
    window.dispatchEvent(new CustomEvent("universe:mask", { detail: {
      width: rect.width,
      height: rect.height,
      open: this.open,
    } }))
  }

  disconnect() {
    this.abort.abort()
    clearTimeout(this.cameraTimer)
    document.body.classList.remove("observation-port-open")
  }
}
