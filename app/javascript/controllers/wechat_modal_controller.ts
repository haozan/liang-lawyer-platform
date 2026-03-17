import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["modal"]

  declare readonly modalTarget: HTMLElement

  connect(): void {
    console.log("WechatModal controller connected")
  }

  // 打开模态框
  open(event: Event): void {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  // 关闭模态框
  close(event: Event): void {
    event.preventDefault()
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  // 点击背景关闭
  closeOnBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.close(event)
    }
  }

  // ESC键关闭
  handleKeydown(event: KeyboardEvent): void {
    if (event.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
      this.close(event)
    }
  }
}
