import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dialogId: String }

  open() {
    const dialog = document.getElementById(this.dialogIdValue)
    if (!dialog) return
    dialog.showModal()
    dialog.querySelector(".paper-close")?.focus()
  }

  close() { this.element.close() }
  backdrop(event) { if (event.target === this.element) this.close() }
}
