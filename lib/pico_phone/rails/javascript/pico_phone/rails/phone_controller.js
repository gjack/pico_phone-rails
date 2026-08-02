import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, region: String, debounce: { type: Number, default: 300 } }
  static targets = ["error"]

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
    if (this.hasErrorTarget) this.errorTarget.textContent = data.valid || data.blank ? "" : data.message
    return data
  }
}
