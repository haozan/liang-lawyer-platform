# frozen_string_literal: true

# TeamAccessible Concern
# 为业务模型（Contract, Case, MajorIssue）提供团队级数据隔离和权限管理
#
# 使用方式:
#   class Contract < ApplicationRecord
#     include TeamAccessible
#   end
#
# 核心功能:
#   1. 三层权限体系：团队所有权 > 团队协作 > 个人授权
#   2. 数据查询：Contract.accessible_by(current_lawyer)
#   3. 权限检查：contract.accessible_by?(current_lawyer)
#   4. 访问级别：contract.access_level_for(current_lawyer) => 'owner' / 'collaborator' / 'viewer'

module TeamAccessible
  extend ActiveSupport::Concern
  
  included do
    # 团队所有权关联（多态）
    has_many :business_team_ownerships, 
             as: :business,
             foreign_key: :business_id,
             dependent: :destroy
    
    has_many :authorized_teams, 
             through: :business_team_ownerships,
             source: :lawyer_team
    
    # 律师个人授权关联（多态）
    has_many :lawyer_business_accesses,
             as: :business,
             foreign_key: :business_id,
             dependent: :destroy
    
    has_many :authorized_lawyers,
             through: :lawyer_business_accesses,
             source: :lawyer
    
    # 创建后自动建立团队归属
    after_create :create_team_ownership
  end
  
  class_methods do
    # 核心查询方法：当前律师可访问的数据
    # @param lawyer [LawyerAccount] 当前律师
    # @return [ActiveRecord::Relation] 可访问的数据集合
    def accessible_by(lawyer)
      return all if lawyer.super_admin?
      
      # 场景1：律师主团队拥有的业务
      team_owned_ids = joins(:business_team_ownerships)
        .where(business_team_ownerships: { lawyer_team_id: lawyer.lawyer_team_id })
        .pluck(:id)
      
      # 场景1.5：律师作为负责人的其他团队拥有的业务
      led_team_ids = LawyerTeam.where(leader_id: lawyer.id).pluck(:id)
      if led_team_ids.any?
        led_teams_owned_ids = joins(:business_team_ownerships)
          .where(business_team_ownerships: { lawyer_team_id: led_team_ids })
          .pluck(:id)
      else
        led_teams_owned_ids = []
      end
      
      # 场景2：律师被个人授权查看的业务
      personally_authorized_ids = joins(:lawyer_business_accesses)
        .where(lawyer_business_accesses: { 
          lawyer_id: lawyer.id
        })
        .where('lawyer_business_accesses.expires_at IS NULL OR lawyer_business_accesses.expires_at > ?', Time.current)
        .pluck(:id)
      
      # 场景3：律师作为案件团队成员参与的案件（仅限 Case 模型）
      if self.name == 'Case'
        team_member_ids = joins(:case_team_members)
          .where(case_team_members: { lawyer_account_id: lawyer.id })
          .pluck(:id)
        
        where(id: (team_owned_ids + led_teams_owned_ids + personally_authorized_ids + team_member_ids).uniq)
      else
        where(id: (team_owned_ids + led_teams_owned_ids + personally_authorized_ids).uniq)
      end
    end
    
    # 律师团队拥有的数据（作为主责团队）
    # @param team_id [Integer] 团队ID
    # @return [ActiveRecord::Relation]
    def owned_by_team(team_id)
      joins(:business_team_ownerships)
        .where(business_team_ownerships: { 
          lawyer_team_id: team_id,
          is_primary: true 
        })
    end
    
    # 律师团队协作的数据（作为协作团队）
    # @param team_id [Integer] 团队ID
    # @return [ActiveRecord::Relation]
    def collaborated_by_team(team_id)
      joins(:business_team_ownerships)
        .where(business_team_ownerships: { 
          lawyer_team_id: team_id,
          is_primary: false 
        })
    end
    
    # 未分配团队的数据（历史数据）
    # @return [ActiveRecord::Relation]
    def unassigned
      left_joins(:business_team_ownerships)
        .where(business_team_ownerships: { id: nil })
    end
  end
  
  # 实例方法：检查律师是否有访问权限
  # @param lawyer [LawyerAccount] 律师对象
  # @return [Boolean]
  def accessible_by?(lawyer)
    # 如果lawyer为nil，直接返回false（企业用户不通过这个方法检查权限）
    return false if lawyer.nil?
    
    return true if lawyer.super_admin?
    return false if lawyer.lawyer_team_id.blank?
    
    # 检查团队权限
    return true if business_team_ownerships.exists?(lawyer_team_id: lawyer.lawyer_team_id)
    
    # 检查是否是其他团队的负责人
    led_team_ids = LawyerTeam.where(leader_id: lawyer.id).pluck(:id)
    return true if led_team_ids.any? && business_team_ownerships.where(lawyer_team_id: led_team_ids).exists?
    
    # 检查个人授权（未过期）
    has_personal_access = lawyer_business_accesses
      .where(lawyer_id: lawyer.id)
      .where('expires_at IS NULL OR expires_at > ?', Time.current)
      .exists?
    return true if has_personal_access
    
    # 检查案件团队成员（仅限 Case）
    if self.is_a?(Case)
      return true if case_team_members.exists?(lawyer_account_id: lawyer.id)
    end
    
    false
  end
  
  # 获取律师对此业务的访问级别
  # @param lawyer [LawyerAccount] 律师对象
  # @return [String, nil] 'owner' / 'collaborator' / 'viewer' / nil
  def access_level_for(lawyer)
    return nil if lawyer.nil?
    return 'owner' if lawyer.super_admin?
    return nil if lawyer.lawyer_team_id.blank?
    
    # 检查团队权限
    team_access = business_team_ownerships
      .find_by(lawyer_team_id: lawyer.lawyer_team_id)
    return team_access.access_level if team_access
    
    # 检查个人授权（未过期）
    personal_access = lawyer_business_accesses
      .where(lawyer_id: lawyer.id)
      .where('expires_at IS NULL OR expires_at > ?', Time.current)
      .first
    return personal_access.access_level if personal_access
    
    # 检查案件团队成员（仅限 Case，默认为 collaborator）
    if self.is_a?(Case) && case_team_members.exists?(lawyer_account_id: lawyer.id)
      return 'collaborator'
    end
    
    nil
  end
  
  # 检查律师是否可以编辑
  # @param lawyer [LawyerAccount]
  # @return [Boolean]
  def editable_by?(lawyer)
    return false if lawyer.nil?
    level = access_level_for(lawyer)
    level.in?(['owner', 'collaborator'])
  end
  
  # 检查律师是否可以删除
  # @param lawyer [LawyerAccount]
  # @return [Boolean]
  def deletable_by?(lawyer)
    return false if lawyer.nil?
    access_level_for(lawyer) == 'owner'
  end
  
  # 获取主责团队
  # @return [LawyerTeam, nil]
  def primary_team
    business_team_ownerships.primary.first&.lawyer_team
  end
  
  # 获取协作团队列表
  # @return [Array<LawyerTeam>]
  def collaborating_teams
    business_team_ownerships.collaborators.map(&:lawyer_team)
  end
  
  # 授权团队访问此业务
  # @param team [LawyerTeam] 团队对象
  # @param access_level [String] 访问级别：'owner' / 'collaborator' / 'viewer'
  # @param authorized_by [LawyerAccount] 授权人
  # @param expires_at [DateTime, nil] 到期时间（可选）
  # @return [BusinessTeamOwnership]
  def grant_team_access!(team:, access_level:, authorized_by:, expires_at: nil)
    business_team_ownerships.create!(
      lawyer_team_id: team.id,
      company_id: self.company_id,
      is_primary: false,
      access_level: access_level,
      authorized_by_id: authorized_by.id,
      expires_at: expires_at
    )
  end
  
  # 授权律师个人访问此业务
  # @param lawyer [LawyerAccount] 律师对象
  # @param access_level [String] 访问级别：'viewer' / 'collaborator'
  # @param reason [String] 授权原因
  # @param authorized_by [LawyerAccount] 授权人
  # @param expires_at [DateTime, nil] 到期时间（可选）
  # @return [LawyerBusinessAccess]
  def grant_lawyer_access!(lawyer:, access_level:, reason:, authorized_by:, expires_at: nil)
    lawyer_business_accesses.create!(
      lawyer_id: lawyer.id,
      access_level: access_level,
      reason: reason,
      authorized_by_id: authorized_by.id,
      expires_at: expires_at
    )
  end
  
  # 撤销团队访问权限
  # @param team [LawyerTeam]
  def revoke_team_access!(team)
    business_team_ownerships.where(lawyer_team_id: team.id, is_primary: false).destroy_all
  end
  
  # 撤销律师个人访问权限
  # @param lawyer [LawyerAccount]
  def revoke_lawyer_access!(lawyer)
    lawyer_business_accesses.where(lawyer_id: lawyer.id).destroy_all
  end
  
  private
  
  # 创建后自动建立团队归属（回调）
  def create_team_ownership
    # 从 Current 中获取当前律师（需要在 ApplicationController 中设置）
    current_lawyer = Current.lawyer_account rescue nil
    
    # 优先级1: 如果企业已经有归属团队，则使用企业的团队
    if self.company.lawyer_team_id.present?
      business_team_ownerships.create!(
        lawyer_team_id: self.company.lawyer_team_id,
        company_id: self.company_id,
        is_primary: true,
        access_level: 'owner',
        authorized_by_id: self.company.lawyer_team.leader_id || current_lawyer&.id
      )
      
      Rails.logger.info "[TeamAccessible] #{self.class.name}##{self.id} 继承企业的团队归属（Team ID: #{self.company.lawyer_team_id}）"
      
    elsif current_lawyer&.lawyer_team_id.present?
      # 优先级2：律师创建业务 - 关联到律师所在团队
      business_team_ownerships.create!(
        lawyer_team_id: current_lawyer.lawyer_team_id,
        company_id: self.company_id,
        is_primary: true,
        access_level: 'owner',
        authorized_by_id: current_lawyer.id
      )
    else
      # 优先级3：企业用户创建业务且企业无团队归属 - 关联到默认律师团队（DEFAULT_TEAM）
      default_team = LawyerTeam.find_by(code: 'DEFAULT_TEAM')
      
      if default_team
        business_team_ownerships.create!(
          lawyer_team_id: default_team.id,
          company_id: self.company_id,
          is_primary: true,
          access_level: 'owner',
          authorized_by_id: default_team.leader_id
        )
        
        Rails.logger.info "[TeamAccessible] 企业用户创建#{self.class.name}##{self.id}，已自动关联到默认律师团队（ID:#{default_team.id}）"
      else
        # 如果没有默认团队，记录警告日志但不中断流程
        Rails.logger.warn "[TeamAccessible] 警告：企业用户创建#{self.class.name}##{self.id}，但系统中不存在DEFAULT_TEAM，此业务将无律师团队关联！"
      end
    end
  end
end
