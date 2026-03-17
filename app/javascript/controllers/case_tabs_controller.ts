import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["tab", "panel"]
  
  declare readonly tabTargets: HTMLElement[]
  declare readonly panelTargets: HTMLElement[]
  
  connect(): void {
    // Show first tab by default or from URL hash
    const hash = window.location.hash.substring(1)
    const targetTab = hash ? this.tabTargets.find(tab => tab.dataset.tabId === hash) : this.tabTargets[0]
    
    if (targetTab) {
      this.showTab(targetTab.dataset.tabId!)
    } else if (this.tabTargets.length > 0) {
      this.showTab(this.tabTargets[0].dataset.tabId!)
    }
  }
  
  switchTab(event: Event): void {
    event.preventDefault()
    const target = event.currentTarget as HTMLElement
    const tabId = target.dataset.tabId
    
    if (tabId) {
      this.showTab(tabId)
      // Update URL hash without scrolling
      history.replaceState(null, '', `#${tabId}`)
    }
  }
  
  showTab(tabId: string): void {
    // Update tab buttons
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tabId === tabId) {
        tab.classList.add('border-primary', 'text-primary')
        tab.classList.remove('border-transparent', 'text-secondary')
      } else {
        tab.classList.remove('border-primary', 'text-primary')
        tab.classList.add('border-transparent', 'text-secondary')
      }
    })
    
    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.tabPanel === tabId) {
        panel.classList.remove('hidden')
      } else {
        panel.classList.add('hidden')
      }
    })
  }
}
