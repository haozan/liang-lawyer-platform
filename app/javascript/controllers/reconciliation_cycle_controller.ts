import { Controller } from "@hotwired/stimulus"

// 对账周期选择控制器
// 功能：点击快捷按钮设置对账周期天数
export default class extends Controller<HTMLElement> {
  static targets = ["input"]
  
  declare readonly inputTarget: HTMLInputElement
  declare readonly hasInputTarget: boolean

  selectCycle(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const days = button.dataset.days
    
    if (days && this.hasInputTarget) {
      // 设置输入框的值
      this.inputTarget.value = days
      
      // 移除所有按钮的激活状态
      this.element.querySelectorAll('button').forEach(btn => {
        btn.classList.remove('bg-primary', 'text-white', 'border-primary')
        btn.classList.add('bg-surface', 'hover:bg-primary', 'hover:text-white', 'hover:border-primary')
      })
      
      // 激活当前按钮
      button.classList.add('bg-primary', 'text-white', 'border-primary')
      button.classList.remove('bg-surface', 'hover:bg-primary', 'hover:text-white', 'hover:border-primary')
    }
  }
}
