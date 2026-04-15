# frozen_string_literal: true

# CasePrefillFromContractService
# 从合同数据预填充新案件的基本信息
#
# 使用方式:
#   CasePrefillFromContractService.new(case_obj: @case, contract: @source_contract).call
#
# 该服务会直接修改 case_obj 的属性（不保存）

class CasePrefillFromContractService < ApplicationService
  attr_reader :case_obj, :contract

  def initialize(case_obj:, contract:)
    @case_obj = case_obj
    @contract = contract
  end

  def call
    prefill_basic_info
    prefill_party_roles
    prefill_summary
    prefill_status_and_stage
    prefill_filing_date
    case_obj
  end

  private

  def prefill_basic_info
    case_obj.name = "《#{contract.name}》纠纷案件"
  end

  def prefill_party_roles
    # 对方角色（诉讼地位）
    case_obj.counterparty_role = contract.counterparty_role if contract.counterparty_role.present?

    # 我方角色（根据对方角色推断）
    case_obj.our_party_role = if contract.counterparty_role.present?
                                contract.counterparty_role == '甲方' ? '被告' : '原告'
                              else
                                '原告'
                              end
  end

  def prefill_summary
    parts = []
    parts << "原合同名称：#{contract.name}"
    parts << "签订日期：#{contract.signed_at.strftime('%Y年%m月%d日')}" if contract.signed_at
    parts << "合同金额：#{contract.contract_amount}#{contract.currency || '元'}" if contract.contract_amount.present?
    parts << "对方：#{contract.counterparty_name}" if contract.counterparty_name.present?
    parts << "对方统一社会信用代码：#{contract.counterparty_unified_code}" if contract.counterparty_unified_code.present?
    parts << "对方法定代表人：#{contract.counterparty_legal_rep}" if contract.counterparty_legal_rep.present?

    if contract.counterparty_contact.present? || contract.counterparty_phone.present?
      contact_info = [contract.counterparty_contact, contract.counterparty_phone].compact.join(' ')
      parts << "对方联系方式：#{contact_info}"
    end

    parts << "争议状态：#{contract.dispute_status}" if contract.dispute_status.present?

    if contract.dispute_occurred_at.present?
      parts << "争议发生日期：#{contract.dispute_occurred_at.strftime('%Y年%m月%d日')}"
    end

    parts << "诉讼标的金额：#{contract.litigation_amount}元" if contract.litigation_amount.present?
    parts << "\n诉讼备注：\n#{contract.litigation_notes}" if contract.litigation_notes.present?

    case_obj.summary = parts.join("\n")
  end

  def prefill_status_and_stage
    case_obj.status = 'investigating'
    case_obj.stage = 'first_trial'
    case_obj.priority = contract.has_high_risk? ? 'high' : 'normal'
  end

  def prefill_filing_date
    # 如果合同有争议发生日期，作为立案日期参考
    case_obj.filing_at = contract.dispute_occurred_at if contract.dispute_occurred_at.present?
  end
end
