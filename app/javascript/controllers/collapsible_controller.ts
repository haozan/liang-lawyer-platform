import { Controller } from "@hotwired/stimulus"

// Collapsible controller - toggles content visibility
// Used for: collapsible announcements, expandable sections
export default class extends Controller<HTMLElement> {
  static targets = ["content", "icon", "toggleText"]
  
  declare readonly contentTarget: HTMLElement
  declare readonly iconTarget: HTMLElement
  declare readonly toggleTextTarget: HTMLElement
  declare readonly hasIconTarget: boolean
  declare readonly hasToggleTextTarget: boolean
  
  connect(): void {
    // Start expanded by default
  }
  
  toggle(): void {
    const isHidden = this.contentTarget.classList.contains('hidden')
    
    if (isHidden) {
      // Expand
      this.contentTarget.classList.remove('hidden')
      if (this.hasIconTarget) {
        this.iconTarget.classList.remove('rotate-180')
      }
      if (this.hasToggleTextTarget) {
        this.toggleTextTarget.textContent = '收起'
      }
    } else {
      // Collapse
      this.contentTarget.classList.add('hidden')
      if (this.hasIconTarget) {
        this.iconTarget.classList.add('rotate-180')
      }
      if (this.hasToggleTextTarget) {
        this.toggleTextTarget.textContent = '展开'
      }
    }
  }
}
