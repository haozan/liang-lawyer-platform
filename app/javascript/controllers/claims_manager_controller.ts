import { Controller } from "@hotwired/stimulus"

// 诉讼请求管理控制器
// 支持动态添加和删除诉讼请求条目
export default class extends Controller<HTMLElement> {
  static targets = ["claimsContainer", "template"]
  
  declare readonly claimsContainerTarget: HTMLElement
  declare readonly templateTarget: HTMLTemplateElement
  
  connect(): void {
    // 初始化
  }
  
  addClaim(event: Event): void {
    event.preventDefault()
    
    // 克隆模板
    const template = this.templateTarget.content.cloneNode(true) as DocumentFragment
    const newRow = template.querySelector('.claim-row') as HTMLElement
    
    if (newRow) {
      // 添加到容器
      this.claimsContainerTarget.appendChild(newRow)
    }
  }
  
  removeClaim(event: Event): void {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    const row = button.closest('.claim-row') as HTMLElement
    
    if (!row) return
    
    // 直接移除该行
    row.remove()
  }
}
