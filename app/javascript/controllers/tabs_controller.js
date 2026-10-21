import { Controller } from "@hotwired/stimulus"

// Switches between panels: <button data-tabs-target="tab" data-action="tabs#select">
// is paired by index with <div data-tabs-target="panel">.
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.show(0)
  }

  select(event) {
    this.show(this.tabTargets.indexOf(event.currentTarget))
  }

  show(index) {
    this.tabTargets.forEach((tab, i) => tab.setAttribute("aria-selected", i === index))
    this.panelTargets.forEach((panel, i) => (panel.hidden = i !== index))
  }
}
