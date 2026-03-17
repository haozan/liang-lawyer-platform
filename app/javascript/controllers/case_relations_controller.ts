import { Controller } from "@hotwired/stimulus"

// 案件关联管理控制器
// 用于案件表单中的占位UI，实际关联功能在案件详情页实现
export default class extends Controller<HTMLElement> {
  static targets = ["container"]
  
  declare readonly containerTarget: HTMLElement
  
  connect(): void {
    // 占位控制器，实际功能在案件详情页
  }
  
  addRelation(event: Event): void {
    event.preventDefault()
    
    // 提示用户
    window.showToast('请在案件创建后，在案件详情页中管理关联关系。', 'info')
  }
}
