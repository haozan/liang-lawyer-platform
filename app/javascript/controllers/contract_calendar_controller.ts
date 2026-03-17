import { Controller } from "@hotwired/stimulus"

/**
 * 合同关键日期日历控制器
 * 
 * 功能：
 * - 月份前后导航
 * - 显示某天的所有事件详情
 * - 模态框交互
 */
export default class extends Controller<HTMLElement> {
  static targets = [
    "yearInput",
    "monthInput",
    "modal",
    "modalTitle",
    "modalContent"
  ]

  declare readonly yearInputTarget: HTMLInputElement
  declare readonly monthInputTarget: HTMLInputElement
  declare readonly modalTarget: HTMLElement
  declare readonly modalTitleTarget: HTMLElement
  declare readonly modalContentTarget: HTMLElement

  connect(): void {
    console.log("ContractCalendar connected")
  }

  // 上一个月
  previousMonth(): void {
    const currentYear = parseInt(this.yearInputTarget.value)
    const currentMonth = parseInt(this.monthInputTarget.value)
    
    let newYear = currentYear
    let newMonth = currentMonth - 1
    
    if (newMonth < 1) {
      newMonth = 12
      newYear -= 1
    }
    
    this.navigateToMonth(newYear, newMonth)
  }

  // 下一个月
  nextMonth(): void {
    const currentYear = parseInt(this.yearInputTarget.value)
    const currentMonth = parseInt(this.monthInputTarget.value)
    
    let newYear = currentYear
    let newMonth = currentMonth + 1
    
    if (newMonth > 12) {
      newMonth = 1
      newYear += 1
    }
    
    this.navigateToMonth(newYear, newMonth)
  }

  // 导航到指定月份
  private navigateToMonth(year: number, month: number): void {
    const form = this.element.querySelector('form')
    if (!form) return
    
    // 更新隐藏字段
    this.yearInputTarget.value = year.toString()
    this.monthInputTarget.value = month.toString()
    
    // 提交表单（Turbo 会自动处理）
    form.requestSubmit()
  }

  // 显示某天的所有事件
  showDayEvents(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const date = button.dataset.date
    const eventsJson = button.dataset.events
    
    if (!date || !eventsJson) return
    
    try {
      const events = JSON.parse(eventsJson)
      
      // 设置标题
      const dateObj = new Date(date)
      const formattedDate = dateObj.toLocaleDateString('zh-CN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        weekday: 'long'
      })
      this.modalTitleTarget.textContent = formattedDate
      
      // 生成事件列表
      const eventHtml = events.map((evt: any) => {
        const colorClasses = this.getColorClasses(evt.color)
        return `
          <a href="/contracts/${evt.contract.id}" 
             class="block p-4 rounded-lg ${colorClasses.bg} hover:shadow-md transition-shadow border ${colorClasses.border}">
            <div class="flex items-start gap-3">
              <div class="${colorClasses.icon}">
                ${this.getIconSvg(evt.icon)}
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-1">
                  <span class="badge ${colorClasses.badge}">${evt.type}</span>
                  <span class="text-xs ${colorClasses.text}">${dateObj.toLocaleDateString('zh-CN')}</span>
                </div>
                <h4 class="font-semibold text-primary truncate">${evt.contract.name}</h4>
                <p class="text-sm ${colorClasses.text} mt-1">
                  ${evt.contract.counterparty_name || ''}
                  ${evt.contract.contract_type ? ` · ${evt.contract.contract_type}` : ''}
                </p>
              </div>
              <svg class="w-5 h-5 text-muted flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
              </svg>
            </div>
          </a>
        `
      }).join('')
      
      this.modalContentTarget.innerHTML = eventHtml
      
      // 显示模态框
      this.modalTarget.classList.remove('hidden')
      
      // 锁定背景滚动
      document.body.style.overflow = 'hidden'
      
    } catch (error) {
      console.error('Failed to parse events:', error)
    }
  }

  // 关闭模态框
  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }

  // 获取颜色类名
  private getColorClasses(color: string): {
    bg: string
    border: string
    text: string
    icon: string
    badge: string
  } {
    const colorMap: Record<string, any> = {
      'info': {
        bg: 'bg-info-50 dark:bg-info-900/20',
        border: 'border-info-200 dark:border-info-800',
        text: 'text-info-700 dark:text-info-300',
        icon: 'text-info-600 dark:text-info-400',
        badge: 'badge-info'
      },
      'success': {
        bg: 'bg-success-50 dark:bg-success-900/20',
        border: 'border-success-200 dark:border-success-800',
        text: 'text-success-700 dark:text-success-300',
        icon: 'text-success-600 dark:text-success-400',
        badge: 'badge-success'
      },
      'warning': {
        bg: 'bg-warning-50 dark:bg-warning-900/20',
        border: 'border-warning-200 dark:border-warning-800',
        text: 'text-warning-700 dark:text-warning-300',
        icon: 'text-warning-600 dark:text-warning-400',
        badge: 'badge-warning'
      },
      'danger': {
        bg: 'bg-danger-50 dark:bg-danger-900/20',
        border: 'border-danger-200 dark:border-danger-800',
        text: 'text-danger-700 dark:text-danger-300',
        icon: 'text-danger-600 dark:text-danger-400',
        badge: 'badge-danger'
      },
      'neutral': {
        bg: 'bg-neutral-50 dark:bg-neutral-900/20',
        border: 'border-neutral-200 dark:border-neutral-800',
        text: 'text-neutral-700 dark:text-neutral-300',
        icon: 'text-neutral-600 dark:text-neutral-400',
        badge: 'badge-neutral'
      }
    }
    
    return colorMap[color] || colorMap['neutral']
  }

  // 获取图标 SVG（简化版，实际应该使用 Lucide 图标）
  private getIconSvg(iconName: string): string {
    // 这里简化处理，实际应该集成完整的 Lucide 图标库
    return `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <circle cx="12" cy="12" r="10"></circle>
    </svg>`
  }

  disconnect(): void {
    // 确保离开时恢复滚动
    document.body.style.overflow = ''
  }
}
