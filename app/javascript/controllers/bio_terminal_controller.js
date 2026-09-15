import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["screen", "acquisition", "currentState", "secondary", "chamberState", "linkState"]

  phase(event) {
    const phase = event.detail.phase
    this.screenTarget.dataset.phase = phase
    const messages = {
      transfer: "NEW SPECIMEN TRANSFER // BIO-CONTAINMENT CHANNEL",
      reconstruction: "BIO-SIGNAL ACQUIRED // OPTICAL RECONSTRUCTION",
      scan: "MORPHOLOGY ACQUISITION // TRACKING LOCK",
      stabilizing: "BEHAVIORAL OBSERVATION // INITIALIZING",
      observation: "SUBJECT LINK // ACTIVE",
      threat: "BEHAVIORAL DEVIATION // THREAT POSTURE",
      impact: "CONTAINMENT EVENT // STABILIZERS ENGAGED",
      recovery: "FLUID CONTROL // RECOVERING"
    }
    if (this.hasAcquisitionTarget) this.acquisitionTarget.textContent = messages[phase] || "SUBJECT LINK // ACTIVE"
    if (this.hasChamberStateTarget) this.chamberStateTarget.textContent = phase === "impact" ? "STRESS" : phase === "recovery" ? "STABILIZING" : phase === "observation" ? "ACTIVE" : "SCANNING"
    if (this.hasLinkStateTarget) this.linkStateTarget.textContent = phase === "observation" ? "LINK LOCKED" : phase === "impact" ? "AMBER RESPONSE" : "SCAN IN PROGRESS"
  }

  state(event) {
    if (this.hasCurrentStateTarget) this.currentStateTarget.textContent = event.detail.state.toUpperCase()
    this.screenTarget.dataset.liveState = event.detail.state
  }

  secondary() {
    if (!this.hasSecondaryTarget) return
    this.secondaryTarget.textContent = this.secondaryTarget.dataset.value
    this.secondaryTarget.classList.add("is-resolved")
  }
}
