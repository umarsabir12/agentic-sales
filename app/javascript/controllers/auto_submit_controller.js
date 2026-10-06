import { Controller } from "@hotwired/stimulus"

// Submits the surrounding form as soon as a field changes (e.g. inline "Assign…" selects).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
