import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.motion = window.matchMedia("(prefers-reduced-motion: reduce)")
    if (this.motion.matches || !window.IntersectionObserver) return
    this.observer = new IntersectionObserver((entries) => {
      if (!entries.some((entry) => entry.isIntersecting)) return
      const siblings = Array.from(this.element.parentElement.children)
      this.element.style.setProperty("--reveal-delay", `${Math.min(siblings.indexOf(this.element) % 3, 2) * 80}ms`)
      this.element.classList.add("is-revealing")
      this.observer.disconnect()
    }, { threshold: .08 })
    this.observer.observe(this.element)
  }

  move(event) {
    if (this.motion.matches || event.pointerType !== "mouse" || window.innerWidth <= 640) return
    // Batch layout reads and style writes into one update per frame.
    this.position = { x: event.clientX, y: event.clientY }
    if (this.frame) return
    this.frame = requestAnimationFrame(() => {
      const rect = this.element.getBoundingClientRect()
      const x = this.position.x - rect.left
      const y = this.position.y - rect.top
      this.element.style.setProperty("--mouse-x", `${x}px`)
      this.element.style.setProperty("--mouse-y", `${y}px`)
      this.element.style.setProperty("--tilt-x", `${(0.5 - y / rect.height) * 5}deg`)
      this.element.style.setProperty("--tilt-y", `${(x / rect.width - 0.5) * 5}deg`)
      this.frame = null
    })
  }

  reset() {
    cancelAnimationFrame(this.frame)
    this.frame = null
    for (const property of ["--mouse-x", "--mouse-y", "--tilt-x", "--tilt-y"]) this.element.style.removeProperty(property)
  }

  disconnect() {
    this.reset()
    this.observer?.disconnect()
    this.element.classList.remove("is-revealing")
  }
}
