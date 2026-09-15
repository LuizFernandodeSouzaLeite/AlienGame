import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["specimen", "scanner", "ring", "sensorArm", "ripple", "fluidWave", "localState"]
  static values = {
    active: Boolean, firstTransfer: Boolean, aggression: Number, curiosity: Number,
    activity: Number, fear: Number, playfulness: Number, reactivity: Number,
    primary: String, secondary: String, archetype: String, impactThreshold: Number
  }

  connect() {
    this.motion = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.facility = this.element.closest(".xenobiology-facility")
    this.abort = new AbortController()
    this.timers = []
    this.observedMilliseconds = 0
    this.lastFrame = performance.now()
    this.secondaryRevealed = false
    this.responseTriggered = false
    this.impactTriggered = false
    this.threatStarted = false
    this.pendingPointer = null
    document.addEventListener("visibilitychange", () => { this.lastFrame = performance.now() }, { signal: this.abort.signal })

    if (!this.activeValue) {
      this.setState("idle")
      return
    }

    this.beginAcquisition()
    this.frame = requestAnimationFrame((time) => this.observe(time))
  }

  beginAcquisition() {
    if (this.motion.matches) {
      this.setPhase("observation")
      this.activate()
      return
    }

    if (this.firstTransferValue) {
      this.setPhase("transfer")
      this.schedule(620, () => this.setPhase("reconstruction"))
      this.schedule(1550, () => this.setPhase("scan"))
      this.schedule(2700, () => this.setPhase("stabilizing"))
      this.schedule(3450, () => this.activate())
    } else {
      this.setPhase("reconstruction")
      this.schedule(360, () => this.setPhase("scan"))
      this.schedule(1450, () => this.activate())
    }
  }

  activate() {
    this.element.dataset.state = "active"
    this.setPhase("observation")
    this.setState(this.initialState())
    this.localStateTarget.textContent = "LOCKED"
  }

  observe(time) {
    const elapsed = Math.min(time - this.lastFrame, 120)
    this.lastFrame = time
    if (this.element.dataset.state === "active" && !document.hidden) {
      this.observedMilliseconds += elapsed
      this.evaluateBehavior()
    }
    this.applyPointerResponse()
    this.frame = requestAnimationFrame((nextTime) => this.observe(nextTime))
  }

  evaluateBehavior() {
    const seconds = this.observedMilliseconds / 1000
    if (!this.secondaryRevealed && seconds >= 4.6) {
      this.secondaryRevealed = true
      this.dispatch("secondary", { trait: this.secondaryValue })
    }
    if (this.qualifiesForImpact() && seconds >= this.impactThresholdValue && !this.threatStarted) this.beginThreat()
    if (!this.responseTriggered && seconds >= 7.5 && !this.qualifiesForImpact()) this.calmResponse()
  }

  qualifiesForImpact() {
    return (this.primaryValue === "AGGRESSIVE" || this.aggressionValue >= 72) && this.fearValue < 82
  }

  beginThreat() {
    if (this.threatStarted) return
    this.threatStarted = true
    this.setPhase("threat")
    this.setState(this.fearValue > 64 ? "defensive" : "agitated")
    this.schedule(this.motion.matches ? 350 : 1050, () => this.impact())
  }

  impact() {
    if (this.impactTriggered || document.hidden || this.element.dataset.state !== "active") return
    this.impactTriggered = true
    this.setPhase("impact")
    this.setState("hostile")
    this.ripple("impact")
    this.fluidWaveTarget.classList.add("is-displaced")
    this.schedule(this.motion.matches ? 500 : 1150, () => {
      this.setPhase("recovery")
      this.setState("recovering")
      this.fluidWaveTarget.classList.remove("is-displaced")
    })
    this.schedule(this.motion.matches ? 1200 : 2800, () => {
      this.setPhase("observation")
      this.setState("watchful")
    })
  }

  calmResponse() {
    this.responseTriggered = true
    const state = this.primaryValue === "TIMID" ? "withdrawn" : this.primaryValue === "PLAYFUL" ? "interested" : this.primaryValue === "CURIOUS" ? "contact" : "calm"
    this.setState(state)
    if (["contact", "interested"].includes(state)) this.ripple("contact")
    this.schedule(1800, () => this.setState(this.initialState()))
  }

  proximity(event) {
    if (!this.activeValue || event.pointerType === "touch") return
    const rect = event.currentTarget.getBoundingClientRect()
    this.pendingPointer = {
      x: ((event.clientX - rect.left) / rect.width - 0.5) * 2,
      y: ((event.clientY - rect.top) / rect.height - 0.5) * 2
    }
  }

  applyPointerResponse() {
    if (!this.pendingPointer || this.motion.matches || this.element.dataset.state !== "active") return
    const { x, y } = this.pendingPointer
    const tendency = this.pointerTendency()
    this.element.style.setProperty("--bio-look-x", `${x * tendency * 12}px`)
    this.element.style.setProperty("--bio-look-y", `${y * tendency * 9}px`)
    this.element.dataset.proximity = tendency < 0 ? "withdraw" : tendency > 0.5 ? "approach" : "observe"
    if (!this.threatStarted) this.setState(tendency < 0 ? "withdrawn" : tendency > 0.5 ? "interested" : "observing")
    this.pendingPointer = null
  }

  leave() {
    this.pendingPointer = null
    this.element.style.removeProperty("--bio-look-x")
    this.element.style.removeProperty("--bio-look-y")
    delete this.element.dataset.proximity
    if (this.element.dataset.state === "active" && !this.threatStarted) this.setState(this.initialState())
  }

  tap(event) {
    if (!this.activeValue) return
    event.preventDefault()
    const rect = event.currentTarget.getBoundingClientRect()
    this.element.style.setProperty("--tap-x", `${event.clientX ? event.clientX - rect.left : rect.width / 2}px`)
    this.element.style.setProperty("--tap-y", `${event.clientY ? event.clientY - rect.top : rect.height / 2}px`)
    this.ripple("tap")
    if (this.primaryValue === "AGGRESSIVE" && this.observedMilliseconds > 4000) this.beginThreat()
    else if (this.primaryValue === "TIMID" || this.fearValue > 72) this.setState("withdrawn")
    else if (this.primaryValue === "CURIOUS" || this.curiosityValue > 68) this.setState("contact")
    else if (this.primaryValue === "PLAYFUL" || this.playfulnessValue > 68) this.setState("interested")
    else this.setState("observing")
  }

  ripple(kind) {
    this.rippleTarget.dataset.kind = kind
    this.rippleTarget.classList.remove("is-active")
    void this.rippleTarget.offsetWidth
    this.rippleTarget.classList.add("is-active")
  }

  pointerTendency() {
    if (this.primaryValue === "TIMID" || this.fearValue > 72) return -0.7
    if (this.primaryValue === "PASSIVE") return 0.12
    if (this.primaryValue === "CURIOUS" || this.primaryValue === "PLAYFUL") return 0.9
    return 0.42
  }

  initialState() {
    if (this.primaryValue === "PASSIVE" || this.primaryValue === "DOCILE") return "calm"
    if (this.primaryValue === "TIMID") return "withdrawn"
    return "observing"
  }

  setPhase(phase) {
    this.element.dataset.phase = phase
    this.facility.dataset.specimenPhase = phase
    this.dispatch("phase", { phase })
  }

  setState(state) {
    this.element.dataset.liveState = state
    this.facility.dataset.specimenState = state
    this.dispatch("state", { state })
  }

  dispatch(name, detail) {
    window.dispatchEvent(new CustomEvent(`specimen:${name}`, { detail: { ...detail, specimenId: this.element.dataset.specimenId } }))
  }

  schedule(delay, callback) {
    this.timers.push(setTimeout(callback, delay))
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    this.timers.forEach((timer) => clearTimeout(timer))
    this.abort.abort()
    this.element.getAnimations({ subtree: true }).forEach((animation) => animation.cancel())
  }
}
