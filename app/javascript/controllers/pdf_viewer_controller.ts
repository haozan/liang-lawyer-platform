import { Controller } from "@hotwired/stimulus"

// Handles PDF file preview in modal or embedded viewer
// Avoids ERR_BLOCKED_BY_CLIENT errors from ad blockers
export default class extends Controller {
  static values = {
    url: String
  }

  declare readonly urlValue: string

  // Open PDF in modal viewer (prevents ad blocker issues)
  preview(event: Event): void {
    event.preventDefault()
    
    // Create modal backdrop
    const backdrop = document.createElement('div')
    backdrop.className = 'fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4'
    backdrop.addEventListener('click', (e) => {
      if (e.target === backdrop) {
        backdrop.remove()
      }
    })

    // Create modal container
    const modal = document.createElement('div')
    modal.className = 'bg-surface rounded-lg shadow-xl w-full h-full max-w-6xl max-h-[90vh] flex flex-col'
    
    // Create header
    const header = document.createElement('div')
    header.className = 'flex items-center justify-between p-4 border-b border-border'

    const title = document.createElement('h3')
    title.className = 'text-lg font-semibold'
    title.textContent = 'PDF 预览'

    const closeBtn = document.createElement('button')
    closeBtn.type = 'button'
    closeBtn.className = 'text-muted hover:text-foreground transition-colors'
    closeBtn.innerHTML = `
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
      </svg>
    `
    closeBtn.addEventListener('click', () => backdrop.remove())

    header.appendChild(title)
    header.appendChild(closeBtn)
    
    // Create iframe for PDF
    const iframe = document.createElement('iframe')
    iframe.src = this.urlValue
    iframe.className = 'w-full flex-1 border-0'
    iframe.setAttribute('allowfullscreen', 'true')
    
    // Assemble modal
    modal.appendChild(header)
    modal.appendChild(iframe)
    backdrop.appendChild(modal)
    document.body.appendChild(backdrop)

    // Close on Escape key
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        backdrop.remove()
        document.removeEventListener('keydown', handleEscape)
      }
    }
    document.addEventListener('keydown', handleEscape)
  }

  close(): void {
    this.element.closest('.fixed')?.remove()
  }
}
