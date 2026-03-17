import { Controller } from "@hotwired/stimulus"

// 多委托人管理控制器
// 支持动态添加和删除委托人企业
export default class extends Controller<HTMLElement> {
  static targets = ["container", "template", "addButton"]
  
  declare readonly containerTarget: HTMLElement
  declare readonly templateTarget: HTMLTemplateElement
  declare readonly addButtonTarget: HTMLButtonElement
  
  private recordIndex: number = 0
  
  connect(): void {
    // 初始化记录索引
    this.recordIndex = this.containerTarget.querySelectorAll('.case-client-row').length
  }
  
  addClient(event: Event): void {
    event.preventDefault()
    
    // 克隆模板
    const template = this.templateTarget.content.cloneNode(true) as DocumentFragment
    const newRow = template.querySelector('.case-client-row') as HTMLElement
    
    if (newRow) {
      // 替换NEW_RECORD为唯一索引
      const html = newRow.innerHTML.replace(/NEW_RECORD/g, String(Date.now() + this.recordIndex))
      newRow.innerHTML = html
      
      // 添加到容器
      this.containerTarget.appendChild(newRow)
      this.recordIndex++
    }
  }
  
  removeClient(event: Event): void {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLButtonElement
    const row = button.closest('.case-client-row') as HTMLElement
    
    if (!row) return
    
    // 检查是否是已存在的记录
    const destroyField = row.querySelector('input[name*="_destroy"]') as HTMLInputElement
    
    if (destroyField) {
      // 已存在的记录：标记为删除
      destroyField.value = '1'
      row.style.display = 'none'
    } else {
      // 新添加的记录：直接移除
      row.remove()
    }
  }
}
