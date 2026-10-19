import { Controller } from "@hotwired/stimulus"

// Show / hide the password in a field.
export default class extends Controller {
  static targets = ["input", "show", "hide"]

  toggle() {
    const hidden = this.inputTarget.type === "password"
    this.inputTarget.type = hidden ? "text" : "password"
    this.showTarget.hidden = hidden
    this.hideTarget.hidden = !hidden
    this.element.querySelector("button").setAttribute("aria-label", hidden ? "Hide password" : "Show password")
  }
}
