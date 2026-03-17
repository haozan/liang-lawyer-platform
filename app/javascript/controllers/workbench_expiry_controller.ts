import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["content", "toggleButton", "toggleText", "toggleIcon"]

  declare readonly contentTarget: HTMLElement
  declare readonly toggleButtonTarget: HTMLButtonElement
  declare readonly toggleTextTarget: HTMLElement
  declare readonly toggleIconTarget: SVGElement

  connect(): void {
    console.log("WorkbenchExpiry connected")
  }

  toggle(): void {
    const isExpanded = !this.contentTarget.classList.contains("hidden")
    
    if (isExpanded) {
      // 收起
      this.contentTarget.classList.add("hidden")
      this.toggleTextTarget.textContent = "展开"
      this.toggleIconTarget.style.transform = "rotate(0deg)"
    } else {
      // 展开
      this.contentTarget.classList.remove("hidden")
      this.toggleTextTarget.textContent = "收起"
      this.toggleIconTarget.style.transform = "rotate(180deg)"
    }
  }
}
