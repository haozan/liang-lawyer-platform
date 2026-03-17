import { Controller } from "@hotwired/stimulus"

// 公告区域折叠/展开控制器
// 支持状态持久化到 localStorage
// 支持通过 data-announcement-toggle-key-value 动态设置 storageKey
export default class extends Controller {
  static targets = ["content", "toggleButton", "toggleIcon", "toggleText"]
  static values = { key: { type: String, default: "announcements_collapsed" } }
  
  declare readonly contentTarget: HTMLElement
  declare readonly toggleButtonTarget: HTMLElement
  declare readonly toggleIconTarget: HTMLElement
  declare readonly toggleTextTarget: HTMLElement
  declare readonly keyValue: string
  
  connect() {
    // 从 localStorage 读取折叠状态，默认为展开（false）
    const isCollapsed = localStorage.getItem(this.keyValue) === "true"
    
    if (isCollapsed) {
      this.collapse(false) // false = 不保存状态（因为是初始化）
    } else {
      this.expand(false)
    }
  }
  
  toggle() {
    const isCurrentlyCollapsed = this.contentTarget.classList.contains("hidden")
    
    if (isCurrentlyCollapsed) {
      this.expand(true)
    } else {
      this.collapse(true)
    }
  }
  
  private expand(saveState: boolean = true) {
    this.contentTarget.classList.remove("hidden")
    this.toggleIconTarget.innerHTML = this.getChevronUpIcon()
    this.toggleTextTarget.textContent = "收起"
    
    if (saveState) {
      localStorage.setItem(this.keyValue, "false")
    }
  }
  
  private collapse(saveState: boolean = true) {
    this.contentTarget.classList.add("hidden")
    this.toggleIconTarget.innerHTML = this.getChevronDownIcon()
    this.toggleTextTarget.textContent = "展开查看"
    
    if (saveState) {
      localStorage.setItem(this.keyValue, "true")
    }
  }
  
  private getChevronUpIcon(): string {
    return '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m18 15-6-6-6 6"/></svg>'
  }
  
  private getChevronDownIcon(): string {
    return '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>'
  }
}
