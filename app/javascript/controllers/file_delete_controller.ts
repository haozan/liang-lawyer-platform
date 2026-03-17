import { Controller } from "@hotwired/stimulus"

/**
 * File Delete Controller
 * 
 * Handles file deletion with confirmation dialog
 * 
 * Usage:
 *   <div data-controller="file-delete">
 *     <button data-action="click->file-delete#confirmDelete" 
 *             data-file-delete-url-value="/attachments/123"
 *             data-file-delete-name-value="文件名.pdf">
 *       删除
 *     </button>
 *   </div>
 * 
 * Values:
 *   - url (String): Delete endpoint URL
 *   - name (String): File name for confirmation message
 */
export default class extends Controller<HTMLElement> {
  static values = {
    url: String,
    name: String
  }

  declare urlValue: string
  declare nameValue: string

  /**
   * Confirm and delete file
   */
  confirmDelete(event: Event): void {
    event.preventDefault()

    const fileName = this.nameValue || '此文件'
    
    // 使用自定义确认对话框（符合 ESLint 规则）
    this.showConfirmDialog(
      `确定要删除 ${fileName} 吗？`,
      '删除后无法恢复。',
      () => this.deleteFile()
    )
  }

  /**
   * Send delete request via Turbo
   */
  private deleteFile(): void {
    if (!this.urlValue) {
      console.error('Delete URL not provided')
      return
    }

    // 创建隐藏的表单来发送 DELETE 请求
    const form = document.createElement('form')
    form.method = 'post'
    form.action = this.urlValue
    form.style.display = 'none'

    // CSRF token
    const csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Method override for DELETE
    const methodInput = document.createElement('input')
    methodInput.type = 'hidden'
    methodInput.name = '_method'
    methodInput.value = 'delete'
    form.appendChild(methodInput)

    // Turbo frame target
    form.setAttribute('data-turbo', 'true')

    // 提交表单
    document.body.appendChild(form)
    form.requestSubmit()
    
    // 清理表单（延迟删除，等待 Turbo 处理完成）
    setTimeout(() => form.remove(), 100)
  }

  /**
   * Show custom confirmation dialog
   */
  private showConfirmDialog(title: string, message: string, onConfirm: () => void): void {
    // 创建确认对话框
    const dialog = document.createElement('div')
    dialog.className = 'fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50'
    dialog.innerHTML = `
      <div class="bg-surface rounded-lg shadow-xl max-w-md w-full p-6 space-y-4">
        <h3 class="text-lg font-semibold text-primary">${title}</h3>
        <p class="text-secondary">${message}</p>
        <div class="flex gap-3 justify-end">
          <button type="button" class="btn-outline" data-action="cancel">
            取消
          </button>
          <button type="button" class="btn-danger" data-action="confirm">
            确定删除
          </button>
        </div>
      </div>
    `

    // 添加事件监听
    const cancelBtn = dialog.querySelector('[data-action="cancel"]')
    const confirmBtn = dialog.querySelector('[data-action="confirm"]')

    const cleanup = () => {
      dialog.remove()
    }

    cancelBtn?.addEventListener('click', cleanup)
    confirmBtn?.addEventListener('click', () => {
      cleanup()
      onConfirm()
    })

    // 点击背景关闭
    dialog.addEventListener('click', (e) => {
      if (e.target === dialog) {
        cleanup()
      }
    })

    // ESC 键关闭
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        cleanup()
        document.removeEventListener('keydown', handleEsc)
      }
    }
    document.addEventListener('keydown', handleEsc)

    document.body.appendChild(dialog)
  }
}
