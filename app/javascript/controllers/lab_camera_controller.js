import { Controller } from "@hotwired/stimulus"

const VIEWS = {
  left:   { background: [1.5, 1, -1], midground: [4, 1.02, -2.2], focus: [8, .9, -3.5], foreground: [13, 1.04, -5] },
  center: { background: [0, 1, 0], midground: [0, 1, 0], focus: [0, 1, 0], foreground: [0, 1, 0] },
  right:  { background: [-1.5, 1, 1], midground: [-4, 1.02, 2.2], focus: [-8, .9, 3.5], foreground: [-13, 1.04, 5] },
}

export default class extends Controller {
  static targets = ["background", "midground", "focus", "foreground", "leftButton", "centerButton", "rightButton", "viewLabel"]
  static values = { view: { type: String, default: "center" } }

  connect() {
    this.motion = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.render(this.viewValue, true)
  }

  left() { this.viewValue = "left" }
  center() { this.viewValue = "center" }
  right() { this.viewValue = "right" }
  viewValueChanged(view) { if (this.motion && this.hasBackgroundTarget) this.render(view) }

  render(view, instant = false) {
    const configuration = VIEWS[view] || VIEWS.center
    for (const [layer, targets] of Object.entries({
      background: this.backgroundTargets,
      midground: this.midgroundTargets,
      focus: this.focusTargets,
      foreground: this.foregroundTargets,
    })) {
      const [x, scale, rotate] = configuration[layer]
      targets.forEach((target) => {
        target.style.transitionDuration = instant || this.motion.matches ? "0ms" : "720ms"
        target.style.setProperty("--camera-x", `${x}vw`)
        target.style.setProperty("--camera-scale", scale)
        target.style.setProperty("--camera-rotate", `${rotate}deg`)
      })
    }
    this.leftButtonTarget.setAttribute("aria-pressed", view === "left")
    this.centerButtonTarget.setAttribute("aria-pressed", view === "center")
    this.rightButtonTarget.setAttribute("aria-pressed", view === "right")
    this.element.dataset.view = view
    if (this.hasViewLabelTarget) this.viewLabelTarget.textContent = view.toUpperCase()
    window.dispatchEvent(new CustomEvent("lab:camera-change"))
  }
}
