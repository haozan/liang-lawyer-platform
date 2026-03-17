import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["content", "chevron", "activeCount"]
  
  declare readonly contentTarget: HTMLElement
  declare readonly chevronTarget: SVGElement
  declare readonly activeCountTarget: HTMLElement
  
  connect(): void {
    this.updateActiveCount()
    
    // Check if any filters are active in URL params
    const urlParams = new URLSearchParams(window.location.search)
    const hasFilters = Array.from(urlParams.keys()).some(key => 
      !['page', 'utf8', 'commit'].includes(key)
    )
    
    // Auto-expand if filters are active
    if (hasFilters) {
      this.expand()
    }
  }
  
  toggle(): void {
    if (this.contentTarget.classList.contains('hidden')) {
      this.expand()
    } else {
      this.collapse()
    }
  }
  
  expand(): void {
    this.contentTarget.classList.remove('hidden')
    this.chevronTarget.style.transform = 'rotate(180deg)'
  }
  
  collapse(): void {
    this.contentTarget.classList.add('hidden')
    this.chevronTarget.style.transform = 'rotate(0deg)'
  }
  
  updateActiveCount(): void {
    const urlParams = new URLSearchParams(window.location.search)
    const filterKeys = ['keyword', 'statuses', 'stages', 'priorities', 'case_types', 
      'company_id', 'team_member_id', 'lead_lawyer_id', 'hearing_days',
      'filed_from', 'filed_to', 'sort_by']
    
    const activeFilters = Array.from(urlParams.keys()).filter(key => 
      filterKeys.includes(key) && urlParams.get(key)
    )
    
    if (activeFilters.length > 0) {
      this.activeCountTarget.textContent = `(${activeFilters.length}个筛选条件生效)`
      this.activeCountTarget.classList.remove('hidden')
    } else {
      this.activeCountTarget.textContent = ''
      this.activeCountTarget.classList.add('hidden')
    }
  }
  
  saveFilter(): void {
    // TODO: 实现自定义模态框以替代 prompt
    // 暂时使用 showToast 提示用户功能未实现
    window.showToast('筛选条件保存功能尚未实现，请稍后使用', 'warning')
    return
    
    // const filterName = prompt('请输入筛选条件名称：')
    // if (!filterName) return
    // 
    // const urlParams = new URLSearchParams(window.location.search)
    // const filterParams: Record<string, string> = {}
    // 
    // urlParams.forEach((value, key) => {
    //   if (key !== 'page' && key !== 'utf8' && key !== 'commit') {
    //     filterParams[key] = value
    //   }
    // })
    // 
    // // Send request to save filter
    // fetch('/case_filters', {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'X-CSRF-Token': this.csrfToken
    //   },
    //   body: JSON.stringify({
    //     case_filter: {
    //       name: filterName,
    //       filter_params: filterParams
    //     }
    //   })
    // })
    //   .then(response => {
    //     if (response.ok) {
    //       showToast('筛选条件已保存！', 'success')
    //       window.location.reload()
    //     } else {
    //       showToast('保存失败，请重试', 'error')
    //     }
    //   })
  }
  
  get csrfToken(): string {
    const meta = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }
}
