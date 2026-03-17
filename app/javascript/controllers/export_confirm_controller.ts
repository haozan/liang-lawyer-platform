import { Controller } from "@hotwired/stimulus"

/**
 * 导出确认控制器
 * 
 * 功能：
 * 1. 点击导出按钮前显示确认信息
 * 2. 显示当前筛选条件和数据量
 * 3. 导出期间显示loading状态
 * 
 * 使用方式：
 * <div data-controller="export-confirm">
 *   <a href="..." 
 *      data-action="click->export-confirm#confirm"
 *      data-export-confirm-type-value="明细表"
 *      data-export-confirm-count-value="123"
 *      data-export-confirm-filters-value='{"企业": "XX公司", "律师": "张律师"}'>
 *     导出明细表
 *   </a>
 * </div>
 */
export default class extends Controller<HTMLElement> {
  static values = {
    type: String,       // 导出类型（明细表、律师汇总表、企业汇总表）
    count: Number,      // 数据量
    filters: Object     // 筛选条件
  }

  declare readonly typeValue: string
  declare readonly countValue: number
  declare readonly filtersValue: Record<string, string>

  connect(): void {
    console.log("ExportConfirm controller connected")
  }

  /**
   * 确认导出
   * 显示确认弹窗，用户确认后才执行导出
   */
  confirm(event: Event): void {
    event.preventDefault()
    
    const link = event.currentTarget as HTMLAnchorElement
    const url = link.href
    
    // 构建筛选条件说明文本
    const filterText = this.buildFilterText()
    
    // 如果有筛选条件或数据量较大，显示提示
    if (filterText || this.countValue > 100) {
      const shouldExport = this.showConfirmation(filterText)
      if (!shouldExport) {
        return
      }
    }
    
    // 开始导出
    this.startExport(link, url)
  }

  /**
   * 显示确认信息
   * 使用浏览器原生 API（临时方案，未来可替换为自定义模态框）
   */
  private showConfirmation(filterText: string): boolean {
    let message = `即将导出 ${this.typeValue}，包含 ${this.countValue} 条数据。\n`
    
    if (filterText) {
      message += `\n当前筛选条件：\n${filterText}\n`
    }
    
    message += "\n确定要导出吗？"
    
    // 使用浏览器原生确认框
    // eslint-disable-next-line no-alert, no-restricted-globals
    return confirm(message)
  }

  /**
   * 开始导出
   * 显示loading状态并执行下载
   */
  private startExport(link: HTMLAnchorElement, url: string): void {
    // 保存原始内容
    const originalHTML = link.innerHTML
    const originalClasses = link.className
    
    // 显示loading状态
    link.innerHTML = `
      <svg class="animate-spin -ml-1 mr-2 h-5 w-5 inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      导出中...
    `
    link.classList.add('opacity-75', 'cursor-wait')
    link.classList.remove('hover:shadow-lg')
    
    // 禁用按钮
    link.style.pointerEvents = 'none'
    
    // 创建隐藏的iframe来触发下载
    const iframe = document.createElement('iframe')
    iframe.style.display = 'none'
    iframe.src = url
    document.body.appendChild(iframe)
    
    // 2秒后恢复按钮状态（给下载一些时间）
    setTimeout(() => {
      link.innerHTML = originalHTML
      link.className = originalClasses
      link.style.pointerEvents = ''
      
      // 移除iframe
      setTimeout(() => {
        document.body.removeChild(iframe)
      }, 1000)
    }, 2000)
  }

  /**
   * 构建筛选条件文本
   */
  private buildFilterText(): string {
    if (!this.filtersValue || Object.keys(this.filtersValue).length === 0) {
      return ''
    }
    
    const filters: string[] = []
    for (const [key, value] of Object.entries(this.filtersValue)) {
      if (value && value !== '全部' && value !== 'all') {
        filters.push(`  • ${key}：${value}`)
      }
    }
    
    return filters.join('\n')
  }
}
