import { Controller } from "@hotwired/stimulus"

// Live preview + one sample-value input per {{n}} variable while writing a new template.
export default class extends Controller {
  static targets = ["header", "body", "footer", "examples", "preview", "buttons"]
  static values = { examples: Array }

  connect() { this.update() }

  update() {
    const body = this.bodyTarget.value
    const count = Math.max(0, ...[...body.matchAll(/\{\{(\d+)\}\}/g)].map(m => parseInt(m[1])))
    this.renderExamples(count)

    const values = this.exampleValues()
    const filled = body.replace(/\{\{(\d+)\}\}/g, (match, n) => values[n - 1] || match)
    this.renderPreview(this.headerTarget.value, filled, this.footerTarget.value, this.buttonLabels())
  }

  exampleValues() {
    return [...this.examplesTarget.querySelectorAll("input")].map(input => input.value)
  }

  renderExamples(count) {
    const current = this.examplesTarget.querySelectorAll("input")
    const values = current.length ? [...current].map(i => i.value) : this.examplesValue
    if (current.length === count) return

    this.examplesTarget.replaceChildren()
    this.examplesTarget.closest("[data-examples-wrapper]").hidden = count === 0
    for (let i = 0; i < count; i++) {
      const label = document.createElement("label")
      label.className = "block text-xs text-gray-500"
      label.textContent = `Sample for {{${i + 1}}}`
      const input = document.createElement("input")
      input.type = "text"
      input.name = "message_template[body_examples][]"
      input.className = "form-control mt-1"
      input.value = values[i] || ""
      input.dataset.action = "input->template-form#update"
      label.append(input)
      this.examplesTarget.append(label)
    }
  }

  buttonLabels() {
    if (!this.hasButtonsTarget) return []
    return [...this.buttonsTarget.querySelectorAll("[data-button-label]")]
      .flatMap(el => el.tagName === "TEXTAREA" ? el.value.split("\n") : [el.value])
      .map(s => s.trim()).filter(Boolean)
  }

  renderPreview(header, body, footer, buttons) {
    const bubble = document.createElement("div")
    bubble.className = "max-w-sm rounded-lg border border-gray-200 bg-surface px-3.5 py-2.5 text-sm shadow-sm"
    if (header.trim()) bubble.append(this.line(header, "font-semibold mb-1"))
    bubble.append(this.line(body || "Your message…", "whitespace-pre-wrap"))
    if (footer.trim()) bubble.append(this.line(footer, "mt-1 text-xs text-gray-500"))
    const wrapper = document.createElement("div")
    wrapper.append(bubble)
    buttons.forEach(label => wrapper.append(this.line(label, "mt-1 max-w-sm rounded-md border border-gray-200 bg-surface py-1.5 text-center text-sm font-medium text-brand-600")))
    this.previewTarget.replaceChildren(wrapper)
  }

  line(text, className) {
    const el = document.createElement("div")
    el.className = className
    el.textContent = text
    return el
  }
}
