import { Controller } from "@hotwired/stimulus"

// Controller for selecting users to mention (@提醒功能)
// Manages a multi-select dropdown where users can select lawyers/company users to notify
export default class extends Controller<HTMLElement> {
  static targets = ["dropdown", "selectedList", "hiddenField", "trigger"]
  
  static values = {
    users: Array,  // Available users: [{type: "LawyerAccount", id: 1, name: "张律师"}, ...]
    selected: Array  // Selected users (same format)
  }
  
  declare readonly dropdownTarget: HTMLElement
  declare readonly selectedListTarget: HTMLElement
  declare readonly hiddenFieldTarget: HTMLInputElement
  declare readonly triggerTarget: HTMLButtonElement
  declare readonly hasTriggerTarget: boolean
  declare usersValue: Array<{type: string, id: number, name: string}>
  declare selectedValue: Array<{type: string, id: number, name: string}>
  private boundCloseDropdown?: (event: Event) => void
  
  connect(): void {
    // Initialize selected value if not set
    if (!this.selectedValue) {
      this.selectedValue = []
    }
    this.updateUI()
    
    // Add document click listener to close dropdown when clicking outside
    this.boundCloseDropdown = this.closeDropdown.bind(this)
    document.addEventListener('click', this.boundCloseDropdown)
  }
  
  disconnect(): void {
    // Remove document click listener
    if (this.boundCloseDropdown) {
      document.removeEventListener('click', this.boundCloseDropdown)
    }
  }
  
  // Toggle dropdown visibility
  toggleDropdown(): void {
    this.dropdownTarget.classList.toggle('hidden')
  }
  
  // Select a user
  selectUser(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const type = button.dataset.userType!
    const id = parseInt(button.dataset.userId!)
    const name = button.dataset.userName!
    
    // Check if already selected
    const exists = this.selectedValue.some(u => u.type === type && u.id === id)
    if (exists) {
      return
    }
    
    // Add to selected
    this.selectedValue = [...this.selectedValue, {type, id, name}]
    this.updateUI()
  }
  
  // Remove a user
  removeUser(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const type = button.dataset.userType!
    const id = parseInt(button.dataset.userId!)
    
    // Remove from selected
    this.selectedValue = this.selectedValue.filter(u => !(u.type === type && u.id === id))
    this.updateUI()
  }
  
  // Update UI (selected badges and hidden field)
  private updateUI(): void {
    // Update hidden field with JSON data
    this.hiddenFieldTarget.value = JSON.stringify(this.selectedValue)
    
    // Update selected badges display
    if (this.selectedValue.length === 0) {
      this.selectedListTarget.innerHTML = '<span class="text-sm text-muted">未选择任何人</span>'
    } else {
      const badges = this.selectedValue.map(user => `
        <span class="inline-flex items-center gap-1 px-2 py-1 bg-primary/10 text-primary rounded text-sm">
          <span>${user.name}</span>
          <button type="button" 
            class="hover:text-danger transition-colors"
            data-action="click->mention-select#removeUser"
            data-user-type="${user.type}"
            data-user-id="${user.id}">
            ×
          </button>
        </span>
      `).join('')
      this.selectedListTarget.innerHTML = badges
    }
    
    // Update trigger button text
    if (this.hasTriggerTarget) {
      const textSpan = this.triggerTarget.querySelector('span')
      if (textSpan) {
        textSpan.textContent = this.selectedValue.length > 0 
          ? `已选择 ${this.selectedValue.length} 人` 
          : '选择提醒对象'
      }
    }
  }
  
  // Close dropdown when clicking outside
  closeDropdown(event: Event): void {
    if (!this.element.contains(event.target as Node)) {
      this.dropdownTarget.classList.add('hidden')
    }
  }
}
