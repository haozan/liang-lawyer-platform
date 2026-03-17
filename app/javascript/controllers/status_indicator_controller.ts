import { Controller } from "@hotwired/stimulus"

// Status Indicator Controller - 状态指示灯
// 根据阈值自动显示红黄绿灯状态
export default class extends Controller<HTMLElement> {
  static values = {
    value: Number,
    thresholds: Object,  // { green: 90, yellow: 70 } 表示 >=90绿灯，>=70黄灯，<70红灯
    reverse: Boolean     // 是否反转逻辑（如逾期率，越低越好）
  }
  
  declare readonly valueValue: number
  declare readonly thresholdsValue: { green: number; yellow: number }
  declare readonly reverseValue: boolean
  
  connect(): void {
    this.updateIndicator()
  }
  
  valueValueChanged(): void {
    this.updateIndicator()
  }
  
  private updateIndicator(): void {
    const status = this.getStatus()
    
    // 移除所有状态类
    this.element.classList.remove('status-green', 'status-yellow', 'status-red')
    
    // 添加当前状态类
    this.element.classList.add(`status-${status}`)
    
    // 更新内容
    this.updateContent(status)
  }
  
  private getStatus(): 'green' | 'yellow' | 'red' {
    const { green, yellow } = this.thresholdsValue
    const value = this.valueValue
    
    if (this.reverseValue) {
      // 反转逻辑：值越低越好
      if (value <= yellow) return 'green'
      if (value <= green) return 'yellow'
      return 'red'
    } else {
      // 正常逻辑：值越高越好
      if (value >= green) return 'green'
      if (value >= yellow) return 'yellow'
      return 'red'
    }
  }
  
  private updateContent(status: 'green' | 'yellow' | 'red'): void {
    const indicator = this.element.querySelector('[data-indicator]')
    if (!indicator) return
    
    // 更新指示灯颜色
    indicator.classList.remove('bg-success', 'bg-warning', 'bg-danger')
    
    switch (status) {
      case 'green':
        indicator.classList.add('bg-success')
        break
      case 'yellow':
        indicator.classList.add('bg-warning')
        break
      case 'red':
        indicator.classList.add('bg-danger')
        break
    }
    
    // 添加脉冲动画（如果是警告或危险状态）
    if (status === 'yellow' || status === 'red') {
      indicator.classList.add('animate-pulse')
    } else {
      indicator.classList.remove('animate-pulse')
    }
  }
}
