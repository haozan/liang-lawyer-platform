import { Controller } from "@hotwired/stimulus"

// Analytics Quick Navigation Floating Button
// Provides a fixed-position button for quick access to different analytics modules
export default class extends Controller<HTMLElement> {
  static targets = ["menu"]
  
  declare readonly menuTarget: HTMLElement
  declare readonly hasMenuTarget: boolean
  
  // State: is menu expanded or collapsed
  private isExpanded: boolean = false
  
  connect(): void {
    // Initialize collapsed state
    this.collapse()
  }
  
  disconnect(): void {
    // Cleanup: ensure menu is hidden
    if (this.hasMenuTarget) {
      this.collapse()
    }
  }
  
  // Toggle menu expansion
  toggle(): void {
    if (this.isExpanded) {
      this.collapse()
    } else {
      this.expand()
    }
  }
  
  // Expand menu
  expand(): void {
    if (!this.hasMenuTarget) return
    
    this.isExpanded = true
    this.menuTarget.classList.remove("hidden")
    
    // Trigger animation
    setTimeout(() => {
      this.menuTarget.classList.add("opacity-100", "translate-y-0")
      this.menuTarget.classList.remove("opacity-0", "translate-y-2")
    }, 10)
  }
  
  // Collapse menu
  collapse(): void {
    if (!this.hasMenuTarget) return
    
    this.isExpanded = false
    this.menuTarget.classList.add("opacity-0", "translate-y-2")
    this.menuTarget.classList.remove("opacity-100", "translate-y-0")
    
    // Wait for animation to complete before hiding
    setTimeout(() => {
      this.menuTarget.classList.add("hidden")
    }, 200)
  }
  
  // Close when clicking outside
  closeOnOutsideClick(event: Event): void {
    if (!this.element.contains(event.target as Node)) {
      this.collapse()
    }
  }
  
  // Handle keyboard shortcuts (Alt+1/2/3)
  handleKeyboard(event: KeyboardEvent): void {
    if (!event.altKey) return
    
    const shortcuts: { [key: string]: string } = {
      '1': 'major_issue',
      '2': 'case', 
      '3': 'contract'
    }
    
    const module = shortcuts[event.key]
    if (module) {
      event.preventDefault()
      this.navigateToModule(module)
    }
  }
  
  // Navigate to analytics module (preserves filter state)
  private navigateToModule(module: string): void {
    const links: { [key: string]: string } = {
      'major_issue': 'dashboard_major_issue_analytics_path',
      'case': 'dashboard_case_analytics_path',
      'contract': 'dashboard_contract_analytics_path'
    }
    
    // Find the corresponding link in the menu
    const link = this.element.querySelector(`[data-analytics-tab="${module}"]`) as HTMLAnchorElement
    if (link) {
      link.click()
    }
  }
}
