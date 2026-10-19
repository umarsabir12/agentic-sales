import { Controller } from "@hotwired/stimulus"

// Four-bar strength meter: length, mixed case, a number, a symbol.
export default class extends Controller {
  static targets = ["input", "bar", "label"]

  update() {
    const value = this.inputTarget.value
    const score = value.length === 0 ? 0 : [
      value.length >= 8,
      /[a-z]/.test(value) && /[A-Z]/.test(value),
      /\d/.test(value),
      /[^A-Za-z0-9]/.test(value)
    ].filter(Boolean).length

    const color = score <= 1 ? "bg-red-500" : score === 2 ? "bg-amber-500" : "bg-green-500"
    this.barTargets.forEach((bar, i) => {
      bar.classList.remove("bg-red-500", "bg-amber-500", "bg-green-500", "bg-gray-200")
      bar.classList.add(i < score ? color : "bg-gray-200")
    })
    this.labelTarget.textContent = value.length === 0 ? "" : ["Too weak", "Weak", "Fair", "Good", "Strong"][score]
  }
}
