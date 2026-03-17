import { Controller } from "@hotwired/stimulus"

// Keyboard shortcut controller for search (Ctrl+K or Cmd+K)
export default class extends Controller<HTMLElement> {
  connect(): void {
    // Listen for keyboard shortcuts globally
    document.addEventListener('keydown', this.handleShortcut.bind(this))
  }
  
  disconnect(): void {
    document.removeEventListener('keydown', this.handleShortcut.bind(this))
  }
  
  handleShortcut(event: KeyboardEvent): void {
    // Ctrl+K or Cmd+K
    if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
      event.preventDefault()
      
      // If already on search page, focus the input
      const searchInput = document.querySelector('input[name="q"]') as HTMLInputElement
      if (searchInput) {
        searchInput.focus()
        searchInput.select()
      } else {
        // Navigate to search page
        window.location.href = '/search'
      }
    }
    
    // ESC to blur search input
    if (event.key === 'Escape') {
      const searchInput = document.querySelector('input[name="q"]') as HTMLInputElement
      if (searchInput && document.activeElement === searchInput) {
        searchInput.blur()
      }
    }
  }
  
  // Handle input keydown (called from navbar search)
  handleInput(event: KeyboardEvent): void {
    // ESC to blur
    if (event.key === 'Escape') {
      const target = event.target as HTMLInputElement
      target.blur()
    }
  }
}
