// Word文档预览控制器
// 使用 mammoth.js 将 .docx 文件转换为 HTML 并在模态框中预览
import { Controller } from "@hotwired/stimulus";
import mammoth from "mammoth";

export default class extends Controller {
  static values = {
    url: String,
  };

  declare readonly urlValue: string;

  private modal: HTMLElement | null = null;

  connect(): void {
    // 控制器初始化
  }

  disconnect(): void {
    // 清理模态框
    this.closeModal();
  }

  // 预览 Word 文档
  async preview(): Promise<void> {
    try {
      // 显示加载状态
      this.showLoadingModal();

      // 下载文件并转换为 ArrayBuffer
      const response = await fetch(this.urlValue);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const arrayBuffer = await response.arrayBuffer();

      // 使用 mammoth 转换 Word 文档为 HTML
      const result = await mammoth.convertToHtml({ arrayBuffer });

      // 显示转换后的内容
      this.showContentModal(result.value);

      // 如果有警告信息，输出到控制台
      if (result.messages.length > 0) {
        console.warn("Word文档转换警告:", result.messages);
      }
    } catch (error) {
      console.error("Word文档预览失败:", error);
      this.showErrorModal(
        error instanceof Error ? error.message : "未知错误"
      );
    }
  }

  // 显示加载中的模态框
  private showLoadingModal(): void {
    this.modal = document.createElement("div");
    this.modal.className =
      "fixed inset-0 bg-black/50 flex items-center justify-center z-50";
    this.modal.innerHTML = `
      <div class="bg-background rounded-lg p-6 max-w-2xl w-full mx-4">
        <div class="flex items-center justify-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
          <span class="ml-4 text-lg">正在加载文档...</span>
        </div>
      </div>
    `;
    document.body.appendChild(this.modal);
  }

  // 显示文档内容的模态框
  private showContentModal(htmlContent: string): void {
    if (!this.modal) return;

    this.modal.innerHTML = `
      <div class="bg-background rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-[90vh] flex flex-col">
        <!-- 头部 -->
        <div class="flex items-center justify-between p-4 border-b border-border">
          <h3 class="text-lg font-semibold text-foreground">文档预览</h3>
          <button 
            type="button"
            class="text-muted hover:text-foreground transition-colors close-modal-btn"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- 内容区域 -->
        <div class="flex-1 overflow-y-auto p-6">
          <div class="prose prose-sm max-w-none word-preview-content">
            ${htmlContent}
          </div>
        </div>

        <!-- 底部 -->
        <div class="flex justify-end p-4 border-t border-border">
          <button 
            type="button"
            class="btn-secondary close-modal-btn"
          >
            关闭
          </button>
        </div>
      </div>
    `;

    // 添加样式
    this.addPreviewStyles();

    // 手动绑定关闭按钮的事件监听器
    this.bindCloseButtons();

    // 点击背景关闭模态框
    this.modal.addEventListener("click", (e) => {
      if (e.target === this.modal) {
        this.closeModal();
      }
    });
  }

  // 显示错误信息的模态框
  private showErrorModal(errorMessage: string): void {
    if (!this.modal) return;

    this.modal.innerHTML = `
      <div class="bg-background rounded-lg shadow-xl max-w-md w-full mx-4">
        <div class="p-6">
          <div class="flex items-center text-danger mb-4">
            <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <h3 class="text-lg font-semibold">预览失败</h3>
          </div>
          <p class="text-muted mb-4">无法预览该文档：${errorMessage}</p>
          <p class="text-sm text-muted mb-6">
            提示：仅支持 .docx 格式的 Word 文档预览。.doc 格式需要下载后用本地软件打开。
          </p>
          <div class="flex justify-end">
            <button 
              type="button"
              class="btn-secondary close-modal-btn"
            >
              关闭
            </button>
          </div>
        </div>
      </div>
    `;

    // 手动绑定关闭按钮的事件监听器
    this.bindCloseButtons();

    // 点击背景关闭模态框
    this.modal.addEventListener("click", (e) => {
      if (e.target === this.modal) {
        this.closeModal();
      }
    });
  }

  // 绑定所有关闭按钮的事件监听器
  private bindCloseButtons(): void {
    if (!this.modal) return;

    const closeButtons = this.modal.querySelectorAll(".close-modal-btn");
    closeButtons.forEach((button) => {
      button.addEventListener("click", () => {
        this.closeModal();
      });
    });
  }

  // 关闭模态框
  closeModal(): void {
    if (this.modal) {
      this.modal.remove();
      this.modal = null;
    }
  }

  // 添加预览样式
  private addPreviewStyles(): void {
    // 检查是否已经添加过样式
    if (document.getElementById("word-preview-styles")) {
      return;
    }

    const style = document.createElement("style");
    style.id = "word-preview-styles";
    style.textContent = `
      .word-preview-content {
        color: hsl(var(--color-foreground));
        line-height: 1.6;
      }
      
      .word-preview-content p {
        margin-bottom: 1em;
      }
      
      .word-preview-content h1,
      .word-preview-content h2,
      .word-preview-content h3,
      .word-preview-content h4,
      .word-preview-content h5,
      .word-preview-content h6 {
        font-weight: 600;
        margin-top: 1.5em;
        margin-bottom: 0.5em;
        color: hsl(var(--color-foreground));
      }
      
      .word-preview-content h1 {
        font-size: 2em;
      }
      
      .word-preview-content h2 {
        font-size: 1.5em;
      }
      
      .word-preview-content h3 {
        font-size: 1.25em;
      }
      
      .word-preview-content ul,
      .word-preview-content ol {
        margin-bottom: 1em;
        padding-left: 2em;
      }
      
      .word-preview-content li {
        margin-bottom: 0.5em;
      }
      
      .word-preview-content table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 1em;
      }
      
      .word-preview-content table td,
      .word-preview-content table th {
        border: 1px solid hsl(var(--color-border));
        padding: 0.5em;
      }
      
      .word-preview-content table th {
        background-color: hsl(var(--color-muted));
        font-weight: 600;
      }
      
      .word-preview-content img {
        max-width: 100%;
        height: auto;
        margin: 1em 0;
      }
      
      .word-preview-content strong {
        font-weight: 600;
      }
      
      .word-preview-content em {
        font-style: italic;
      }
    `;
    document.head.appendChild(style);
  }
}
