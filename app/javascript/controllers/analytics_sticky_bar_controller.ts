import { Controller } from "@hotwired/stimulus"

// Analytics Sticky Bar Controller - 数据分析页面顶部固定栏
// 滚动时自动吸附到页面顶部，展示关键指标
export default class extends Controller<HTMLElement> {
  static targets = ["bar"]
  
  declare readonly barTarget: HTMLElement
  
  private observer: IntersectionObserver | null = null
  private isSticky = false
  
  connect(): void {
    this.setupObserver()
  }
  
  disconnect(): void {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
  
  private setupObserver(): void {
    const options = {
      root: null,
      threshold: 0,
      rootMargin: '-80px 0px 0px 0px' // 考虑导航栏高度
    }
    
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (!entry.isIntersecting && !this.isSticky) {
          this.makeSticky()
        } else if (entry.isIntersecting && this.isSticky) {
          this.removeSticky()
        }
      })
    }, options)
    
    // 观察一个触发元素（通常是顶部栏之前的元素）
    const trigger = this.element.querySelector('[data-sticky-trigger]')
    if (trigger) {
      this.observer.observe(trigger)
    }
  }
  
  private makeSticky(): void {
    this.isSticky = true
    this.barTarget.classList.add('fixed', 'top-16', 'left-0', 'right-0', 'z-40', 'shadow-lg', 'animate-in', 'slide-in-from-top-2')
    this.barTarget.classList.remove('relative')
  }
  
  private removeSticky(): void {
    this.isSticky = false
    this.barTarget.classList.remove('fixed', 'top-16', 'left-0', 'right-0', 'z-40', 'shadow-lg', 'animate-in', 'slide-in-from-top-2')
    this.barTarget.classList.add('relative')
  }
}
