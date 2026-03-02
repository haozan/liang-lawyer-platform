# Create demo data for the legal contract risk management platform

puts "🏢 Creating demo companies..."
company1 = Company.create!(name: "佛山金属制品有限公司")
company2 = Company.create!(name: "东莞建材贸易公司")

puts "⚖️  Creating lawyer accounts..."
# 主任律师
lawyer1 = LawyerAccount.create!(
  name: "梁家航",
  email: "liang@lawyer.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'lawyer'
)

# 团队律师
lawyer2 = LawyerAccount.create!(
  name: "梁婉华",
  email: "liang.wh@lawyer.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'lawyer'
)

lawyer3 = LawyerAccount.create!(
  name: "袁丽华",
  email: "yuan.lh@lawyer.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'lawyer'
)

# 实习律师（使用助理角色）
assistant1 = LawyerAccount.create!(
  name: "邓敏儿",
  email: "deng.me@lawyer.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'assistant'
)

# 律师助理
assistant2 = LawyerAccount.create!(
  name: "张雅欣",
  email: "zhang.yx@lawyer.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'assistant'
)

puts "👥 Creating company user accounts..."
# Company 1 users
boss1 = company1.company_users.create!(
  name: "#{company1.name}老板",
  phone: "13800138001",
  password: "password123",
  password_confirmation: "password123",
  role: 'boss'
)

executive1 = company1.company_users.create!(
  name: "#{company1.name}高管",
  phone: "13800138002",
  password: "password123",
  password_confirmation: "password123",
  role: 'executive'
)

employee1 = company1.company_users.create!(
  name: "#{company1.name}员工",
  phone: "13800138003",
  password: "password123",
  password_confirmation: "password123",
  role: 'employee'
)

# Company 2 users
boss2 = company2.company_users.create!(
  name: "#{company2.name}老板",
  phone: "13900139001",
  password: "password123",
  password_confirmation: "password123",
  role: 'boss'
)

employee2 = company2.company_users.create!(
  name: "#{company2.name}员工",
  phone: "13900139002",
  password: "password123",
  password_confirmation: "password123",
  role: 'employee'
)

puts "📄 Creating contract records for #{company1.name}..."
require 'tempfile'

temp_file1 = Tempfile.new(['contract', '.pdf'])
temp_file1.write("PDF content for steel purchase contract")
temp_file1.rewind

contract1 = company1.contracts.new(
  name: "钢材采购合同-广州钢铁厂",
  signed_at: 1.year.ago,
  end_at: 2.months.from_now,
  status: 'active'
)
contract1.file.attach(io: temp_file1, filename: 'contract1.pdf', content_type: 'application/pdf')
contract1.save!
temp_file1.close

temp_file2 = Tempfile.new(['contract', '.pdf'])
temp_file2.write("PDF content for equipment lease contract")
temp_file2.rewind

contract2 = company1.contracts.new(
  name: "设备租赁合同-深圳机械公司",
  signed_at: 3.months.ago,
  end_at: 9.months.from_now,
  status: 'active'
)
contract2.file.attach(io: temp_file2, filename: 'contract2.pdf', content_type: 'application/pdf')
contract2.save!
temp_file2.close

puts "💬 Creating comments for contracts..."
contract1.comments.create!(
  author_name: "梁家航律师",
  author_role: "lawyer",
  content: "该合同即将到期，建议提前与对方沟通续签事宜。注意检查历史履约情况，若有违约记录建议调整合同条款。"
)

contract1.comments.create!(
  author_name: employee1.name,
  author_role: "employee",
  content: "已与对方负责人联系，对方表示愿意续签，价格条款需要重新商议。"
)

puts "⚖️  Creating case records for #{company1.name}..."
case1 = company1.cases.create!(
  name: "合同纠纷案-钢材质量问题",
  case_number: "(2024)粤0105民初12345号",
  case_type: "合同纠纷",
  court_name: "佛山市南海区人民法院",
  status: "in_court",
  filing_at: 2.months.ago,
  hearing_at: 1.week.from_now.change(hour: 9, min: 30),
  summary: "因钢材质量不符合合同约定，对方拒绝付款，我方起诉要求支付货款及违约金。"
)

case2 = company1.cases.create!(
  name: "设备租赁纠纷",
  case_number: "(2024)粤0106民初23456号",
  case_type: "租赁合同纠纷",
  court_name: "佛山市顺德区人民法院",
  status: "judgement",
  filing_at: 4.months.ago,
  hearing_at: 1.month.ago,
  judgement_received_at: 1.week.ago,
  summary: "租赁设备损坏，对方要求赔偿，我方认为属于正常损耗。"
)

puts "💬 Creating comments for cases..."
case1.comments.create!(
  author_name: assistant1.name,
  author_role: "assistant",
  content: "已完成起诉状准备，证据材料已整理完毕。",
  review_status: "pending_review"
)

case1.comments.create!(
  author_name: lawyer1.name,
  author_role: "lawyer",
  content: "案件材料已审核，下周一开庭，请公司负责人准时到庭。"
)

puts "💡 Creating major issue records for #{company1.name}..."
issue1 = company1.major_issues.create!(
  title: "新产品出口合规性审查",
  issue_type: "合规审查",
  description: "公司计划出口新型金属制品到东南亚，需要律师审查出口合规性和相关法律风险。",
  priority: "high",
  status: "discussing",
  mentioned_lawyer: lawyer1
)

issue2 = company1.major_issues.create!(
  title: "员工社保补缴方案咨询",
  issue_type: "劳动纠纷",
  description: "部分老员工社保有断缴情况，需要咨询补缴方案和潜在法律风险。",
  priority: "medium",
  status: "pending",
  mentioned_lawyer: lawyer1
)

puts "💬 Creating comments for major issues..."
issue1.comments.create!(
  author_name: employee1.name,
  author_role: "employee",
  content: "附上了产品详细参数和目标国家信息，请律师查阅。"
)

issue1.comments.create!(
  author_name: lawyer1.name,
  author_role: "lawyer",
  content: "已初步审查，需要补充目标国家的进口标准文件，建议联系当地律所协助办理。"
)

puts "📄 Creating reconciliation records..."
contract1.reconciliations.create!(
  period: 1.month.ago.strftime('%Y-%m'),
  uploaded_by: employee1.name,
  uploaded_at: 1.month.ago,
  notes: '11月对账单，钢材采购15万元'
)

puts "✅ Demo data created successfully!"
puts ""
puts "Login credentials:"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "Boss account:"
puts "  Phone: 13800138001"
puts "  Password: password123"
puts ""
puts "Executive account:"
puts "  Phone: 13800138002"
puts "  Password: password123"
puts ""
puts "Employee account:"
puts "  Phone: 13800138003"
puts "  Password: password123"
puts ""
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "⚠️  梁家航律师团队账户 (5人)"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts ""
puts "👨‍⚖️ 主任律师 - 梁家航"
puts "  Email: liang@lawyer.com"
puts "  Password: password123"
puts ""
puts "👩‍⚖️ 律师 - 梁婉华"
puts "  Email: liang.wh@lawyer.com"
puts "  Password: password123"
puts ""
puts "👩‍⚖️ 律师 - 袁丽华"
puts "  Email: yuan.lh@lawyer.com"
puts "  Password: password123"
puts ""
puts "💼 实习律师 - 邓敏儿"
puts "  Email: deng.me@lawyer.com"
puts "  Password: password123"
puts ""
puts "💼 律师助理 - 张雅欣"
puts "  Email: zhang.yx@lawyer.com"
puts "  Password: password123"
