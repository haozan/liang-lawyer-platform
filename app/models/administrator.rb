class Administrator < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  # 允许中国手机号（1[3-9]xxxxxxxxx）或保留的系统默认号 10000000000
  # ⚠️ 不要移除 10000000000：这是首次部署时创建的默认 admin 账号的占位手机号
  validates :phone, presence: true, uniqueness: true,
    format: {
      with: /\A(1[3-9]\d{9}|10000000000)\z/,
      message: '必须是有效的中国手机号码'
    }
  validates :role, presence: true, inclusion: { in: %w[admin super_admin] }
  has_secure_password

  has_many :admin_oplogs, dependent: :destroy
  
  # Normalize phone before saving
  before_save :normalize_phone

  # Role constants
  ROLES = %w[admin super_admin].freeze

  # Role check methods
  def super_admin?
    role == 'super_admin'
  end

  def admin?
    role == 'admin'
  end

  # Permission check methods
  def can_manage_administrators?
    super_admin?
  end

  def can_delete_administrators?
    super_admin?
  end

  def can_be_deleted_by?(current_admin)
    return false unless current_admin.can_delete_administrators?
    # Super admin cannot delete themselves
    return false if self == current_admin
    true
  end

  # Display role name
  def role_name
    case role
    when 'super_admin'
      'Super Admin'
    when 'admin'
      'Admin'
    else
      role.humanize
    end
  end

  # Role options for form select
  def self.role_options
    [
      ['Admin', 'admin'],
      ['Super Admin', 'super_admin']
    ]
  end
  
  private
  
  def normalize_phone
    self.phone = phone.to_s.strip if phone.present?
  end
end
