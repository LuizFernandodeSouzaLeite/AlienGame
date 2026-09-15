import { Controller } from "@hotwired/stimulus"

// Gives roaming specimens (free_swimming / floating / orbital / radial_drift
// locomotion) an actual path through the tank instead of a fixed position.
// Reuses the existing specimen-chamber controller as the single source of
// truth for behavioral state (it already tracks pointer proximity and the
// aggressive/calm event sequence) — this controller only turns that state
// into a *destination* and eases the specimen toward it. Non-roaming
// specimens (crystalline/amorphous/insectoid anchors, suspended humanoids)
// are left untouched by design; their existing proximity nudge still works.
const REGIONS = {
  upperLeft: [-0.3, -0.26], upperRight: [0.3, -0.26],
  lowerLeft: [-0.26, 0.24], lowerRight: [0.26, 0.24],
  leftSensor: [-0.37, -0.02], rightSensor: [0.37, -0.02],
  rest: [0, 0.3], frontGlass: [0, -0.06], center: [0, 0],
}
const WANDER_REGIONS = Object.keys(REGIONS).filter((name) => name !== "center")
const SPEED = { free_swimming: 0.05, orbital: 0.045, radial_drift: 0.035, floating: 0.018 }

export default class extends Controller {
  static targets = ["specimen", "bounds"]
  static values = { active: Boolean, roams: Boolean, locomotion: String }

  connect() {
    this.motion = window.matchMedia("(prefers-reduced-motion: reduce)")
    if (!this.activeValue || !this.roamsValue || !this.hasSpecimenTarget || !this.hasBoundsTarget) return

    this.memory = []
    this.pos = { x: 0, y: 0 }
    this.target = REGIONS.center
    this.pointer = null
    this.paused = false
    this.specimenTarget.classList.add("is-roaming")

    this.abort = new AbortController()
    const opts = { signal: this.abort.signal }
    window.addEventListener("resize", () => this.measure(), opts)
    this.boundsTarget.addEventListener("pointermove", (event) => this.trackPointer(event), { ...opts, passive: true })
    this.boundsTarget.addEventListener("pointerleave", () => { this.pointer = null }, opts)
    window.addEventListener("specimen:state", (event) => this.onStateChange(event), opts)
    window.addEventListener("specimen:phase", (event) => this.onPhaseChange(event), opts)
    document.addEventListener("visibilitychange", () => { if (!document.hidden) this.measure() }, opts)

    this.measure()
    this.pickTarget()
    this.thinkTimer = setInterval(() => this.think(), 2200 + Math.random() * 1600)
    if (!this.motion.matches) this.frame = requestAnimationFrame((time) => this.loop(time))
  }

  disconnect() {
    this.abort?.abort()
    cancelAnimationFrame(this.frame)
    clearInterval(this.thinkTimer)
  }

  measure() {
    const rect = this.boundsTarget.getBoundingClientRect()
    this.bw = rect.width || 1
    this.bh = rect.height || 1
  }

  trackPointer(event) {
    const rect = this.boundsTarget.getBoundingClientRect()
    this.pointer = { x: (event.clientX - rect.left) / rect.width - 0.5 }
  }

  matchesSpecimen(event) {
    return String(event.detail?.specimenId) === String(this.element.dataset.specimenId)
  }

  onStateChange(event) {
    if (!this.matchesSpecimen(event)) return
    const { state } = event.detail
    if (state === "withdrawn") this.pickTarget("avoid")
    else if (state === "interested" || state === "contact") this.pickTarget("approach")
    else if (state === "observing" || state === "calm") this.pickTarget("wander")
  }

  onPhaseChange(event) {
    if (!this.matchesSpecimen(event)) return
    const { phase } = event.detail
    if (phase === "threat") this.paused = true
    else if (phase === "impact") { this.paused = false; this.pickTarget("lunge") }
    else if (phase === "recovery" || phase === "observation") this.paused = false
  }

  think() {
    if (this.paused || document.hidden) return
    this.pickTarget("wander")
  }

  pickTarget(mode = "wander") {
    let choice
    if (mode === "avoid" && this.pointer) {
      choice = this.pointer.x > 0 ? "leftSensor" : "rightSensor"
    } else if (mode === "approach" || mode === "lunge") {
      choice = "frontGlass"
    } else {
      const pool = WANDER_REGIONS.filter((name) => !this.memory.includes(name))
      choice = (pool.length ? pool : WANDER_REGIONS)[Math.floor(Math.random() * (pool.length || WANDER_REGIONS.length))]
    }
    this.target = REGIONS[choice] || REGIONS.center
    this.memory.unshift(choice)
    this.memory = this.memory.slice(0, 2)

    if (this.motion.matches) this.settle()
  }

  settle() {
    this.pos.x = this.target[0]
    this.pos.y = this.target[1]
    this.write()
  }

  loop() {
    if (!document.hidden) {
      const speed = SPEED[this.locomotionValue] ?? 0.03
      this.pos.x += (this.target[0] - this.pos.x) * speed
      this.pos.y += (this.target[1] - this.pos.y) * speed
      this.write()
    }
    this.frame = requestAnimationFrame(() => this.loop())
  }

  write() {
    this.specimenTarget.style.setProperty("--loco-x", `${(this.pos.x * this.bw).toFixed(1)}px`)
    this.specimenTarget.style.setProperty("--loco-y", `${(this.pos.y * this.bh).toFixed(1)}px`)
  }
}
