import { Controller } from "@hotwired/stimulus"

// Image preview modal with zoom functionality
export default class extends Controller<HTMLElement> {
  static values = {
    url: String  // Image URL to preview
  }

  declare readonly urlValue: string

  private modal: HTMLElement | null = null
  private img: HTMLImageElement | null = null
  private scale: number = 1
  private readonly scaleStep: number = 0.2
  private readonly minScale: number = 0.5
  private readonly maxScale: number = 3

  connect(): void {
    // Modal will be created dynamically when needed
  }

  disconnect(): void {
    this.closeModal()
  }

  // Open image preview modal
  open(event: Event): void {
    event.preventDefault()
    
    if (!this.urlValue) {
      console.error("Image URL not provided")
      return
    }

    this.createModal()
    this.showModal()
  }

  // Create modal structure
  private createModal(): void {
    if (this.modal) return

    // Create modal backdrop
    this.modal = document.createElement('div')
    this.modal.className = 'image-preview-modal'
    this.modal.innerHTML = `
      <div class="image-preview-backdrop" data-action="click->image-preview#close"></div>
      <div class="image-preview-content">
        <div class="image-preview-toolbar">
          <button type="button" class="image-preview-btn" data-action="click->image-preview#zoomIn" title="放大 (+)">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><path d="m21 21-4.35-4.35"></path><line x1="11" y1="8" x2="11" y2="14"></line><line x1="8" y1="11" x2="14" y2="11"></line></svg>
          </button>
          <button type="button" class="image-preview-btn" data-action="click->image-preview#zoomOut" title="缩小 (-)">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><path d="m21 21-4.35-4.35"></path><line x1="8" y1="11" x2="14" y2="11"></line></svg>
          </button>
          <button type="button" class="image-preview-btn" data-action="click->image-preview#resetZoom" title="重置 (0)">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8"></path><path d="M21 3v5h-5"></path></svg>
          </button>
          <button type="button" class="image-preview-btn image-preview-close" data-action="click->image-preview#close" title="关闭 (ESC)">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
          </button>
        </div>
        <div class="image-preview-container">
          <img src="${this.urlValue}" alt="预览" class="image-preview-img" />
        </div>
      </div>
    `

    document.body.appendChild(this.modal)
    this.img = this.modal.querySelector('.image-preview-img')

    // Add keyboard event listener
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.handleKeydown)
  }

  // Show modal with animation
  private showModal(): void {
    if (!this.modal) return

    requestAnimationFrame(() => {
      this.modal!.classList.add('active')
      document.body.style.overflow = 'hidden'
    })
  }

  // Close modal
  close(event?: Event): void {
    if (event) {
      event.preventDefault()
    }

    this.closeModal()
  }

  private closeModal(): void {
    if (!this.modal) return

    this.modal.classList.remove('active')
    document.body.style.overflow = ''

    // Remove modal after animation
    setTimeout(() => {
      if (this.modal) {
        this.modal.remove()
        this.modal = null
        this.img = null
        this.scale = 1
      }
    }, 300)

    // Remove keyboard listener
    document.removeEventListener('keydown', this.handleKeydown)
  }

  // Zoom in
  zoomIn(event: Event): void {
    event.preventDefault()
    this.setScale(this.scale + this.scaleStep)
  }

  // Zoom out
  zoomOut(event: Event): void {
    event.preventDefault()
    this.setScale(this.scale - this.scaleStep)
  }

  // Reset zoom
  resetZoom(event: Event): void {
    event.preventDefault()
    this.setScale(1)
  }

  // Set image scale
  private setScale(newScale: number): void {
    if (!this.img) return

    this.scale = Math.max(this.minScale, Math.min(this.maxScale, newScale))
    this.img.style.transform = `scale(${this.scale})`
  }

  // Handle keyboard shortcuts
  private handleKeydown(event: KeyboardEvent): void {
    if (!this.modal) return

    switch (event.key) {
      case 'Escape':
        this.closeModal()
        break
      case '+':
      case '=':
        event.preventDefault()
        this.setScale(this.scale + this.scaleStep)
        break
      case '-':
      case '_':
        event.preventDefault()
        this.setScale(this.scale - this.scaleStep)
        break
      case '0':
        event.preventDefault()
        this.setScale(1)
        break
    }
  }
}
