import { Controller } from "@hotwired/stimulus"

/**
 * Case Team Controller
 * 处理案件团队成员的动态添加和删除
 */
export default class extends Controller<HTMLElement> {
  static targets = [
    "container",      // 团队成员容器
    "template",       // 成员行模板
    "addButton"       // 添加按钮
  ]

  static values = {
    memberCount: { type: Number, default: 0 }  // 当前成员数量
  }

  declare readonly containerTarget: HTMLElement
  declare readonly templateTarget: HTMLTemplateElement
  declare readonly addButtonTarget: HTMLButtonElement
  declare memberCountValue: number

  connect(): void {
    console.log("CaseTeam controller connected")
    // 初始化时统计现有成员数量
    this.memberCountValue = this.containerTarget.querySelectorAll('.team-member-row').length
  }

  /**
   * 添加新的团队成员行
   */
  addMember(event: Event): void {
    event.preventDefault()
    
    // 克隆模板
    const template = this.templateTarget.content.cloneNode(true) as DocumentFragment
    const memberRow = template.querySelector('.team-member-row') as HTMLElement
    
    if (!memberRow) {
      console.error('Team member row template not found')
      return
    }
    
    // 替换索引占位符
    const index = this.memberCountValue
    memberRow.innerHTML = memberRow.innerHTML.replace(/NEW_RECORD/g, `new_${index}`)
    
    // 添加到容器
    this.containerTarget.appendChild(template)
    
    // 增加计数
    this.memberCountValue++
    
    // 聚焦到新添加的角色选择框
    const roleSelect = memberRow.querySelector('select[name*="[role]"]') as HTMLSelectElement
    if (roleSelect) {
      roleSelect.focus()
    }
  }

  /**
   * 删除团队成员行
   */
  removeMember(event: Event): void {
    event.preventDefault()
    
    const button = event.currentTarget as HTMLElement
    const memberRow = button.closest('.team-member-row') as HTMLElement
    
    if (!memberRow) {
      console.error('Team member row not found')
      return
    }
    
    // 检查是否有 _destroy 隐藏字段（用于已保存的记录）
    const destroyInput = memberRow.querySelector('input[name*="[_destroy]"]') as HTMLInputElement
    
    if (destroyInput) {
      // 已保存的记录：标记为删除
      destroyInput.value = '1'
      memberRow.style.display = 'none'
    } else {
      // 新添加未保存的记录：直接移除DOM
      memberRow.remove()
    }
    
    // 减少计数
    this.memberCountValue--
  }

  /**
   * 角色改变时的处理
   * 用于根据角色过滤可选的律师/助理
   */
  roleChanged(event: Event): void {
    const select = event.currentTarget as HTMLSelectElement
    const memberRow = select.closest('.team-member-row') as HTMLElement
    
    if (!memberRow) return
    
    const role = select.value
    const lawyerSelect = memberRow.querySelector('select[name*="[lawyer_account_id]"]') as HTMLSelectElement
    
    if (!lawyerSelect) return
    
    // 根据角色显示/隐藏律师选项
    Array.from(lawyerSelect.options).forEach((option: HTMLOptionElement) => {
      const lawyerRole = option.dataset.role
      
      if (role === 'legal_assistant') {
        // 律师助理：只显示助理
        option.hidden = lawyerRole !== 'assistant'
      } else {
        // 主办律师/辅助律师：只显示律师
        option.hidden = lawyerRole !== 'lawyer'
      }
    })
    
    // 重置选择
    lawyerSelect.value = ''
  }
}
