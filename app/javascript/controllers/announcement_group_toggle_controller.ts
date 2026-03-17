import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["content", "icon"]
  
  static values = {
    groupKey: String
  }
  
  declare readonly contentTarget: HTMLElement
  declare readonly iconTarget: HTMLElement
  declare readonly groupKeyValue: string
  
  connect(): void {
    // 从 localStorage 读取折叠状态
    const storageKey = this.storageKey()
    const isCollapsed = localStorage.getItem(storageKey) === 'true'
    
    if (isCollapsed) {
      this.collapse()
    } else {
      this.expand()
    }
  }
  
  disconnect(): void {
    // 清理工作（如需要）
  }
  
  toggle(): void {
    if (this.isCollapsed()) {
      this.expand()
    } else {
      this.collapse()
    }
  }
  
  private expand(): void {
    this.contentTarget.classList.remove("hidden")
    this.iconTarget.classList.remove("rotate-180")
    this.saveState(false)
  }
  
  private collapse(): void {
    this.contentTarget.classList.add("hidden")
    this.iconTarget.classList.add("rotate-180")
    this.saveState(true)
  }
  
  private isCollapsed(): boolean {
    return this.contentTarget.classList.contains("hidden")
  }
  
  private saveState(collapsed: boolean): void {
    localStorage.setItem(this.storageKey(), collapsed.toString())
  }
  
  private storageKey(): string {
    return `announcement_group_${this.groupKeyValue}_collapsed`
  }
}
