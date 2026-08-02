import { Controller } from "@hotwired/stimulus"

// data-controller sits on the <input> itself, which can't have children --
// so the error element (a sibling, placed wherever the caller wants) is
// unreachable via Stimulus's normal descendant-scoped static targets.
// Found by hand instead, scoped to the input's parent.
export default class extends Controller {
  static values = { url: String, region: String, debounce: { type: Number, default: 300 } }

  connect() {
    this.errorElement = this.element.parentElement?.querySelector('[data-phone-target="error"]') ?? null
  }

  validate() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.check(), this.debounceValue)
  }

  async reformat() {
    const data = await this.check()
    if (data.valid) this.element.value = data.national
  }

  async check() {
    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({ phone: this.element.value, region: this.regionValue }),
    })
    const data = await response.json()
    if (this.errorElement) this.errorElement.textContent = data.valid || data.blank ? "" : data.message
    return data
  }
}
