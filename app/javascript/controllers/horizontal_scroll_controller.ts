import { Controller } from "@hotwired/stimulus"

// 企业导航栏横向滚动控制器
// 功能：
// 1. 监听滚动事件，动态显示/隐藏左右渐变遮罩
// 2. 支持鼠标滚轮横向滚动
// 3. 支持左右箭头按钮点击滚动
export default class extends Controller {
  static targets = ["leftFade", "rightFade", "scrollContainer"]
  
  declare readonly leftFadeTarget: HTMLElement
  declare readonly rightFadeTarget: HTMLElement
  declare readonly scrollContainerTarget: HTMLElement
  declare readonly hasLeftFadeTarget: boolean
  declare readonly hasRightFadeTarget: boolean
  declare readonly hasScrollContainerTarget: boolean
  
  connect() {
    this.updateFadeVisibility()
    
    // 监听滚动容器的滚动事件
    if (this.hasScrollContainerTarget) {
      this.scrollContainerTarget.addEventListener('scroll', () => this.updateFadeVisibility())
    }
  }
  
  disconnect() {
    if (this.hasScrollContainerTarget) {
      this.scrollContainerTarget.removeEventListener('scroll', () => this.updateFadeVisibility())
    }
  }
  
  // 更新渐变遮罩的可见性
  updateFadeVisibility() {
    if (!this.hasScrollContainerTarget) return
    
    const scrollLeft = this.scrollContainerTarget.scrollLeft
    const scrollWidth = this.scrollContainerTarget.scrollWidth
    const clientWidth = this.scrollContainerTarget.clientWidth
    
    // 显示/隐藏左侧渐变
    if (this.hasLeftFadeTarget) {
      if (scrollLeft > 10) {
        this.leftFadeTarget.style.display = 'block'
      } else {
        this.leftFadeTarget.style.display = 'none'
      }
    }
    
    // 显示/隐藏右侧渐变
    if (this.hasRightFadeTarget) {
      if (scrollLeft + clientWidth < scrollWidth - 10) {
        this.rightFadeTarget.style.display = 'block'
      } else {
        this.rightFadeTarget.style.display = 'none'
      }
    }
  }
  
  // 向左滚动
  scrollLeft() {
    if (!this.hasScrollContainerTarget) return
    
    this.scrollContainerTarget.scrollBy({
      left: -200,
      behavior: 'smooth'
    })
  }
  
  // 向右滚动
  scrollRight() {
    if (!this.hasScrollContainerTarget) return
    
    this.scrollContainerTarget.scrollBy({
      left: 200,
      behavior: 'smooth'
    })
  }
}
