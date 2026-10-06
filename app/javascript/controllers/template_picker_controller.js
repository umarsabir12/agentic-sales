import { Controller } from "@hotwired/stimulus"

// Picks an approved template to send and asks for a value per {{n}} variable.
export default class extends Controller {
  static targets = ["select", "fields", "preview"]
  static values = { name: String, params: Array }

  connect() { this.change() }

  change() {
    const option = this.selectTarget.selectedOptions[0]
    const count = option ? parseInt(option.dataset.variables || "0") : 0
    const previous = [...this.fieldsTarget.querySelectorAll("input")].map(i => i.value)
    const values = previous.length ? previous : this.paramsValue

    this.fieldsTarget.replaceChildren()
    for (let i = 0; i < count; i++) {
      const label = document.createElement("label")
      label.className = "block text-sm"
      label.textContent = `Value for {{${i + 1}}}`
      const input = document.createElement("input")
      input.type = "text"
      input.required = true
      input.name = `${this.nameValue}[template_params][]`
      input.className = "form-control mt-1"
      input.value = values[i] || ""
      input.dataset.action = "input->template-picker#render"
      label.append(input)
      this.fieldsTarget.append(label)
    }
    this.render()
  }

  render() {
    const option = this.selectTarget.selectedOptions[0]
    if (!option || !option.value) {
      this.previewTarget.textContent = "Choose a template to see a preview."
      return
    }
    const values = [...this.fieldsTarget.querySelectorAll("input")].map(i => i.value)
    this.previewTarget.textContent = option.dataset.body.replace(/\{\{(\d+)\}\}/g, (match, n) => values[n - 1] || match)
  }
}
