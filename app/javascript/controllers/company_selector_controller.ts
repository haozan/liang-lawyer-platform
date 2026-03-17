import { Controller } from "@hotwired/stimulus"

// 企业选择器控制器 - 支持搜索过滤
export default class extends Controller<HTMLElement> {
  static targets = ["menu", "searchInput", "companyList", "companyItem", "selectedText"]
  
  declare readonly menuTarget: HTMLElement
  declare readonly searchInputTarget: HTMLInputElement
  declare readonly companyListTarget: HTMLElement
  declare readonly companyItemTargets: HTMLElement[]
  declare readonly selectedTextTarget: HTMLElement
  
  connect(): void {
    // 点击外部关闭菜单
    document.addEventListener('click', this.handleClickOutside.bind(this))
  }
  
  disconnect(): void {
    document.removeEventListener('click', this.handleClickOutside.bind(this))
  }
  
  // 切换下拉菜单显示/隐藏
  toggle(event: Event): void {
    event.stopPropagation()
    const isHidden = this.menuTarget.classList.contains('hidden')
    
    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }
  
  // 打开菜单
  open(): void {
    this.menuTarget.classList.remove('hidden')
    // 聚焦搜索框
    setTimeout(() => {
      this.searchInputTarget.focus()
    }, 100)
  }
  
  // 关闭菜单
  close(): void {
    this.menuTarget.classList.add('hidden')
    // 清空搜索框
    this.searchInputTarget.value = ''
    // 显示所有企业
    this.companyItemTargets.forEach(item => {
      item.style.display = ''
    })
  }
  
  // 搜索过滤
  search(event: Event): void {
    const searchTerm = (event.target as HTMLInputElement).value.toLowerCase().trim()
    
    let visibleCount = 0
    this.companyItemTargets.forEach(item => {
      const companyName = item.dataset.companyName?.toLowerCase() || ''
      const match = companyName.includes(searchTerm)
      
      if (match) {
        item.style.display = ''
        visibleCount++
      } else {
        item.style.display = 'none'
      }
    })
    
    // 显示/隐藏"无结果"提示
    this.updateNoResultsMessage(visibleCount === 0)
  }
  
  // 点击外部关闭
  handleClickOutside(event: Event): void {
    const target = event.target as HTMLElement
    if (!this.element.contains(target)) {
      this.close()
    }
  }
  
  // 阻止点击菜单内部时关闭
  preventClose(event: Event): void {
    event.stopPropagation()
  }
  
  // 更新"无结果"提示
  updateNoResultsMessage(show: boolean): void {
    let noResultsDiv = this.companyListTarget.querySelector('.no-results') as HTMLElement
    
    if (show) {
      if (!noResultsDiv) {
        noResultsDiv = document.createElement('div')
        noResultsDiv.className = 'no-results px-4 py-8 text-center text-muted'
        noResultsDiv.innerHTML = `
          <svg class="w-12 h-12 mx-auto mb-2 text-muted opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
          </svg>
          <p class="text-sm">未找到匹配的企业</p>
        `
        this.companyListTarget.appendChild(noResultsDiv)
      }
      noResultsDiv.style.display = ''
    } else {
      if (noResultsDiv) {
        noResultsDiv.style.display = 'none'
      }
    }
  }
}
