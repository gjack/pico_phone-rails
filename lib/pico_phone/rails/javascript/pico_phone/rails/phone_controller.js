import { Controller } from "@hotwired/stimulus"

// data-controller sits on the <input> itself, which can't have children --
// so the error element (a sibling, placed wherever the caller wants) is
// unreachable via Stimulus's normal descendant-scoped static targets.
// Found by hand instead, scoped to the input's parent.
export default class extends Controller {
  static values = { url: String, region: String, strict: { type: Boolean, default: true }, debounce: { type: Number, default: 300 } }

  connect() {
    this.errorElement = this.element.parentElement?.querySelector('[data-phone-target="error"]') ?? null
  }

  validate() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.check(), this.debounceValue)
  }

  async reformat() {
    const data = await this.check()
    const formatted = data.national ?? data.international
    if (formatted) this.element.value = formatted
  }

  async check() {
    const headers = { "Content-Type": "application/json", Accept: "application/json" }
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) headers["X-CSRF-Token"] = csrfToken

    const response = await fetch(this.urlValue, {
      method: "POST",
      headers,
      body: JSON.stringify({ phone: this.element.value, region: this.regionValue, strict: this.strictValue }),
    })
    const data = await response.json()
    if (this.errorElement) this.errorElement.textContent = data.valid || data.blank ? "" : data.message
    return data
  }
}
