import { Controller } from "@hotwired/stimulus"

// Floating search button controller (mobile + global access)
// Shows a fixed button at bottom-right corner that opens search page
export default class extends Controller<HTMLElement> {
  static targets = ["button"]
  
  declare readonly buttonTarget: HTMLButtonElement
  declare readonly hasButtonTarget: boolean
  
  connect(): void {
    // Hide on search page itself
    if (window.location.pathname === '/search') {
      this.element.classList.add('hidden')
    }
    
    // Show/hide based on scroll position (hide when scrolling down, show when scrolling up)
    let lastScrollTop = 0
    let scrollTimeout: number | null = null
    
    window.addEventListener('scroll', () => {
      const st = window.pageYOffset || document.documentElement.scrollTop
      
      // Clear previous timeout
      if (scrollTimeout) {
        clearTimeout(scrollTimeout)
      }
      
      // Hide while scrolling
      if (this.hasButtonTarget) {
        this.buttonTarget.classList.add('opacity-50', 'scale-90')
      }
      
      // Show after scrolling stops
      scrollTimeout = window.setTimeout(() => {
        if (this.hasButtonTarget) {
          this.buttonTarget.classList.remove('opacity-50', 'scale-90')
        }
      }, 150)
      
      lastScrollTop = st <= 0 ? 0 : st
    }, { passive: true })
  }
  
  // Navigate to search page
  openSearch(): void {
    window.location.href = '/search'
  }
}
