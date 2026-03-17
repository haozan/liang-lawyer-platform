import { Controller } from "@hotwired/stimulus"

// 根据案件阶段动态更新可选的诉讼地位
export default class extends Controller {
  static targets = ["stage", "ourRole"]
  
  declare readonly stageTarget: HTMLSelectElement
  declare readonly ourRoleTarget: HTMLSelectElement
  
  // 诉讼地位选项配置
  private readonly partyRolesByStage: Record<string, Array<[string, string]>> = {
    arbitration: [
      ['原告/申请人', '原告'],
      ['被告/被申请人', '被告']
    ],
    first_trial: [
      ['原告/申请人', '原告'],
      ['被告/被申请人', '被告']
    ],
    second_trial: [
      ['上诉人', '上诉人'],
      ['被上诉人', '被上诉人']
    ],
    execution: [
      ['申请执行人', '申请执行人'],
      ['被执行人', '被执行人']
    ],
    retrial: [
      ['再审申请人', '再审申请人'],
      ['再审被申请人', '再审被申请人']
    ],
    resume_execution: [
      ['申请执行人', '申请执行人'],
      ['被执行人', '被执行人']
    ]
  }
  
  // 所有诉讼地位选项（当未选择阶段时）
  private readonly allPartyRoles: Array<[string, string]> = [
    ['原告/申请人', '原告'],
    ['被告/被申请人', '被告'],
    ['上诉人', '上诉人'],
    ['被上诉人', '被上诉人'],
    ['再审申请人', '再审申请人'],
    ['再审被申请人', '再审被申请人'],
    ['申请执行人', '申请执行人'],
    ['被执行人', '被执行人']
  ]
  
  updateRoles(): void {
    const stage = this.stageTarget.value
    const currentValue = this.ourRoleTarget.value
    
    // 获取当前阶段对应的诉讼地位选项
    const roles = stage ? this.partyRolesByStage[stage] : this.allPartyRoles
    
    if (!roles) {
      console.warn(`Unknown stage: ${stage}`)
      return
    }
    
    // 清空现有选项
    this.ourRoleTarget.innerHTML = '<option value="">请选择我方诉讼地位</option>'
    
    // 添加新选项
    roles.forEach(([label, value]) => {
      const option = document.createElement('option')
      option.value = value
      option.textContent = label
      
      // 保持原有选择（如果在新选项中）
      if (value === currentValue) {
        option.selected = true
      }
      
      this.ourRoleTarget.appendChild(option)
    })
  }
}
