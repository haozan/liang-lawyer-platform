import BaseChannelController from "./base_channel_controller"

/**
 * MajorIssue Controller - Handles WebSocket + UI for major issue real-time discussion
 *
 * Server sends JSON with 'type' field, automatically routes to handleXxx() methods
 */
export default class extends BaseChannelController {
  static targets = [
    "commentsList",
    "typingIndicator",
    "commentInput"
  ]

  static values = {
    streamName: String,
    currentUserName: String,
    currentUserRole: String
  }

  declare readonly commentsListTarget: HTMLElement
  declare readonly typingIndicatorTarget: HTMLElement
  declare readonly commentInputTarget: HTMLTextAreaElement
  declare readonly streamNameValue: string
  declare readonly currentUserNameValue: string
  declare readonly currentUserRoleValue: string
  declare readonly hasCommentsListTarget: boolean
  declare readonly hasTypingIndicatorTarget: boolean
  
  private typingTimeout: number | null = null
  private typingUsers: Set<string> = new Set()

  connect(): void {
    console.log("MajorIssue controller connected")

    this.createSubscription("MajorIssueChannel", {
      stream_name: this.streamNameValue
    })
  }

  disconnect(): void {
    this.destroySubscription()
  }

  protected channelConnected(): void {
    console.log('MajorIssue WebSocket connected')
  }

  protected channelDisconnected(): void {
    console.log('MajorIssue WebSocket disconnected')
  }

  // 处理新评论
  protected handleNewComment(data: any): void {
    console.log('New comment:', data)
    
    if (!this.hasCommentsListTarget) return
    
    // 创建新评论元素
    const commentEl = this.createCommentElement(data)
    this.commentsListTarget.appendChild(commentEl)
    
    // 滚动到底部
    this.scrollToBottom()
    
    // 显示通知（如果不是当前用户的评论）
    if (data.author_name !== this.currentUserNameValue) {
      this.showNotification(`${data.author_name} 发表了新评论`)
    }
  }
  
  // 处理打字提示
  protected handleUserTyping(data: any): void {
    if (data.user_name === this.currentUserNameValue) return
    
    this.typingUsers.add(data.user_name)
    this.updateTypingIndicator()
  }
  
  // 处理停止打字
  protected handleUserStopTyping(data: any): void {
    this.typingUsers.delete(data.user_name)
    this.updateTypingIndicator()
  }

  // UI方法：发送打字提示
  onTyping(): void {
    // 清除之前的timeout
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout)
    }
    
    // 发送打字事件
    this.perform('typing', {
      user_name: this.currentUserNameValue,
      user_role: this.currentUserRoleValue
    })
    
    // 3秒后发送停止打字事件
    this.typingTimeout = window.setTimeout(() => {
      this.perform('stop_typing', {
        user_name: this.currentUserNameValue
      })
    }, 3000)
  }
  
  // UI方法：滚动到底部
  private scrollToBottom(): void {
    if (this.hasCommentsListTarget) {
      this.commentsListTarget.scrollTop = this.commentsListTarget.scrollHeight
    }
  }
  
  // UI方法：创建评论元素
  private createCommentElement(data: any): HTMLElement {
    const div = document.createElement('div')
    div.className = 'comment-item p-4 border-b border-border'
    
    const roleClass = data.author_role === 'lawyer' ? 'text-primary' : 'text-secondary'
    
    div.innerHTML = `
      <div class="flex items-start gap-3">
        <div class="flex-1">
          <div class="flex items-center gap-2 mb-2">
            <span class="font-medium ${roleClass}">${this.escapeHtml(data.author_name)}</span>
            <span class="text-xs text-muted">${this.formatTime(data.created_at)}</span>
          </div>
          <div class="text-foreground whitespace-pre-wrap">${this.escapeHtml(data.content)}</div>
        </div>
      </div>
    `
    
    return div
  }
  
  // UI方法：更新打字提示
  private updateTypingIndicator(): void {
    if (!this.hasTypingIndicatorTarget) return
    
    if (this.typingUsers.size === 0) {
      this.typingIndicatorTarget.classList.add('hidden')
      return
    }
    
    this.typingIndicatorTarget.classList.remove('hidden')
    const users = Array.from(this.typingUsers).join(', ')
    this.typingIndicatorTarget.textContent = `${users} 正在输入...`
  }
  
  // UI方法：显示通知
  private showNotification(message: string): void {
    // 简单的通知实现（可以替换为更好的UI库）
    const notification = document.createElement('div')
    notification.className = 'fixed bottom-4 right-4 bg-primary text-primary-foreground px-4 py-2 rounded-lg shadow-lg z-50'
    notification.textContent = message
    document.body.appendChild(notification)
    
    setTimeout(() => {
      notification.remove()
    }, 3000)
  }
  
  // 工具方法：转义HTML
  private escapeHtml(text: string): string {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
  
  // 工具方法：格式化时间
  private formatTime(isoString: string): string {
    const date = new Date(isoString)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    
    if (diff < 60000) return '刚刚'
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
    
    return date.toLocaleString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }
}
