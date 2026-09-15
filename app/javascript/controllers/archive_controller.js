import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "handle"]

  toggle() {
    const open = !this.element.classList.contains("is-open")
    this.element.classList.toggle("is-open", open)
    this.handleTarget.setAttribute("aria-expanded", open)
    this.drawerTarget.setAttribute("aria-hidden", !open)
  }
}
