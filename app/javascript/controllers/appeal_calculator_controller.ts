import { Controller } from "@hotwired/stimulus"

/**
 * 上诉期限自动计算控制器
 * 
 * 当用户填写判决书领取日期时，根据案件阶段自动计算上诉/再审期限届满日
 * 
 * Targets:
 *   - deadline: 上诉期限届满日输入框
 * 
 * Actions:
 *   - calculate: 当判决书日期改变时触发计算
 */
export default class extends Controller {
  static targets = ["deadline"]

  declare readonly deadlineTarget: HTMLInputElement

  calculate(event: Event) {
    const judgementDateInput = event.target as HTMLInputElement
    const judgementDate = judgementDateInput.value
    
    if (!judgementDate) {
      return
    }

    // 获取案件阶段
    const stageSelect = document.querySelector('select[name="case[stage]"]') as HTMLSelectElement
    if (!stageSelect) {
      return
    }

    const stage = stageSelect.value
    
    // 计算上诉期限
    const deadline = this.calculateDeadline(judgementDate, stage)
    
    if (deadline && !this.deadlineTarget.value) {
      // 只在目标输入框为空时自动填充
      this.deadlineTarget.value = deadline
      
      // 添加视觉反馈
      this.deadlineTarget.classList.add('ring-2', 'ring-primary', 'ring-opacity-50')
      setTimeout(() => {
        this.deadlineTarget.classList.remove('ring-2', 'ring-primary', 'ring-opacity-50')
      }, 1000)
    }
  }

  private calculateDeadline(judgementDate: string, stage: string): string | null {
    const date = new Date(judgementDate)
    
    if (isNaN(date.getTime())) {
      return null
    }

    let deadlineDate: Date

    switch (stage) {
      case 'first_trial':
        // 一审：15天上诉期
        deadlineDate = new Date(date)
        deadlineDate.setDate(deadlineDate.getDate() + 15)
        break
      case 'second_trial':
      case 'arbitration':
        // 二审/仲裁：6个月再审期
        deadlineDate = new Date(date)
        deadlineDate.setMonth(deadlineDate.getMonth() + 6)
        break
      default:
        // 默认使用一审规则
        deadlineDate = new Date(date)
        deadlineDate.setDate(deadlineDate.getDate() + 15)
        break
    }

    // 格式化为 YYYY-MM-DD
    return deadlineDate.toISOString().split('T')[0]
  }
}
