# ============================================================
# 极光法律服务管理系统 — 演示数据
# ============================================================

puts "🔄 清理旧数据..."
CompanyMembership.delete_all
CompanyUser.delete_all
Company.delete_all
LawyerAccount.delete_all

# ============================================================
# 1. 律师账号
# ============================================================
puts "⚖️  创建律师账号..."

lawyer1 = LawyerAccount.create!(
  name: "梁家航", phone: "18718708876",
  password: "888888", password_confirmation: "888888",
  role: 'lawyer'
)
lawyer2 = LawyerAccount.create!(
  name: "梁婉华", phone: "13360232005",
  password: "888888", password_confirmation: "888888",
  role: 'lawyer'
)
lawyer3 = LawyerAccount.create!(
  name: "袁丽华", phone: "13760060761",
  password: "888888", password_confirmation: "888888",
  role: 'lawyer'
)
assistant1 = LawyerAccount.create!(
  name: "邓敏儿", phone: "13413891863",
  password: "888888", password_confirmation: "888888",
  role: 'assistant'
)
assistant2 = LawyerAccount.create!(
  name: "张雅欣", phone: "15811946010",
  password: "888888", password_confirmation: "888888",
  role: 'assistant'
)

puts "  ✓ 创建了 #{LawyerAccount.count} 个律师账号"

# ============================================================
# 2. 企业
# ============================================================
puts "🏢 创建企业..."

company1 = Company.create!(name: "佛山金属制品有限公司", status: 'active')
company2 = Company.create!(name: "东莞建材贸易公司", status: 'active')
company3 = Company.create!(name: "广州科技发展有限公司", status: 'active',
                           service_expires_at: 1.year.from_now)
company4 = Company.create!(name: "深圳电子商务公司", status: 'active')
company5 = Company.create!(name: "珠海物流运输有限公司", status: 'active')
company6 = Company.create!(name: "中山制造业集团", status: 'active')

puts "  ✓ 创建了 #{Company.count} 个企业"

# ============================================================
# 3. 企业用户（账号，手机全局唯一）
# ============================================================
puts "👥 创建企业用户..."

# 佛山金属
user_fsb = CompanyUser.create!(name: "陈老板", phone: "13800138001", password: "888888", password_confirmation: "888888")
user_fse = CompanyUser.create!(name: "王员工", phone: "13800138002", password: "888888", password_confirmation: "888888")

# 东莞建材
user_dgb = CompanyUser.create!(name: "李老板", phone: "13900139001", password: "888888", password_confirmation: "888888")
user_dge = CompanyUser.create!(name: "张员工", phone: "13900139002", password: "888888", password_confirmation: "888888")

# 广州科技
user_gzb = CompanyUser.create!(name: "刘总", phone: "13500135001", password: "888888", password_confirmation: "888888")

# 深圳电商
user_szb = CompanyUser.create!(name: "赵总", phone: "13600136001", password: "888888", password_confirmation: "888888")
user_sze = CompanyUser.create!(name: "孙员工", phone: "13600136002", password: "888888", password_confirmation: "888888")

# 跨企业用户（在多个企业）
user_cross = CompanyUser.create!(name: "吴志远", phone: "13700137001", password: "888888", password_confirmation: "888888")

puts "  ✓ 创建了 #{CompanyUser.count} 个企业用户"

# ============================================================
# 4. 关联企业成员（company_memberships）
# ============================================================
puts "🔗 关联企业成员..."

# 佛山金属
CompanyMembership.create!(company: company1, company_user: user_fsb, role: 'boss')
CompanyMembership.create!(company: company1, company_user: user_fse, role: 'employee')

# 东莞建材
CompanyMembership.create!(company: company2, company_user: user_dgb, role: 'boss')
CompanyMembership.create!(company: company2, company_user: user_dge, role: 'employee')

# 广州科技
CompanyMembership.create!(company: company3, company_user: user_gzb, role: 'boss')

# 深圳电商
CompanyMembership.create!(company: company4, company_user: user_szb, role: 'boss')
CompanyMembership.create!(company: company4, company_user: user_sze, role: 'employee')

# 跨企业用户：吴志远同时在珠海 + 中山
CompanyMembership.create!(company: company5, company_user: user_cross, role: 'boss')
CompanyMembership.create!(company: company6, company_user: user_cross, role: 'employee')

puts "  ✓ 创建了 #{CompanyMembership.count} 条企业成员关联"

# ============================================================
# 汇总
# ============================================================
puts ""
puts "✅ 演示数据创建完成！"
puts ""
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "律师登录（密码均为 888888）："
LawyerAccount.ordered.each do |l|
  puts "  #{l.phone}  #{l.name}（#{l.role_display}）"
end
puts ""
puts "企业用户登录（密码均为 888888）："
CompanyUser.ordered.each do |u|
  companies_str = u.companies.map { |c| "#{c.name}·#{u.role_in(c) == 'boss' ? '老板' : '员工'}" }.join('  ')
  puts "  #{u.phone}  #{u.name}  => #{companies_str}"
end
puts ""
puts "特殊演示：吴志远（13700137001）属于两个企业，登录后需选择企业。"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
