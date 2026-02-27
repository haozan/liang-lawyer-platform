# Create demo data for the legal risk management platform

puts "🏢 Creating demo companies..."
company1 = Company.create!(name: "佛山金属制品有限公司")
company2 = Company.create!(name: "东莞建材贸易公司")

puts "⚖️  Creating lawyer accounts..."
lawyer1 = LawyerAccount.create!(
  name: "梁家航",
  email: "liang@lawyer.com",
  password: "password123",
  password_confirmation: "password123"
)

lawyer2 = LawyerAccount.create!(
  name: "律师助理",
  email: "assistant@lawyer.com",
  password: "password123",
  password_confirmation: "password123"
)

puts "👥 Creating company user accounts..."
# Company 1 users
hr_user1 = company1.company_users.create!(
  name: "#{company1.name}人事",
  email: "hr@foshan-metal.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'hr'
)

contract_user1 = company1.company_users.create!(
  name: "#{company1.name}合同",
  email: "contract@foshan-metal.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'contract'
)

# Company 2 users
hr_user2 = company2.company_users.create!(
  name: "#{company2.name}人事",
  email: "hr@dongguan-building.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'hr'
)

contract_user2 = company2.company_users.create!(
  name: "#{company2.name}合同",
  email: "contract@dongguan-building.com",
  password: "password123",
  password_confirmation: "password123",
  role: 'contract'
)

puts "📋 Creating employee records for #{company1.name}..."
employee1 = company1.employees.create!(
  name: "张三",
  gender: "男",
  id_number: "440105199001011234",
  position: "生产主管",
  salary: 8000,
  hired_at: 2.years.ago,
  probation_end_at: 2.years.ago + 3.months,
  social_insurance_at: 2.years.ago,
  contract_signed_at: 2.years.ago,
  contract_end_at: 25.days.from_now # Expiring soon!
)

employee2 = company1.employees.create!(
  name: "李四",
  gender: "女",
  id_number: "440106199202021234",
  position: "质检员",
  salary: 6000,
  hired_at: 1.year.ago,
  probation_end_at: 1.year.ago + 3.months,
  social_insurance_at: 1.year.ago,
  contract_signed_at: 1.year.ago,
  contract_end_at: 11.months.from_now
)

employee3 = company1.employees.create!(
  name: "王五",
  gender: "男",
  id_number: "440107199505051234",
  position: "仓管员",
  salary: 5500,
  hired_at: 6.months.ago,
  probation_end_at: 3.months.ago,
  social_insurance_at: 6.months.ago,
  contract_signed_at: 6.months.ago,
  contract_end_at: 1.year.from_now + 6.months
)

puts "💬 Creating comments for employee records..."
employee1.comments.create!(
  author_name: "律师团队",
  author_role: "lawyer",
  content: "该员工劳动合同即将到期（#{employee1.contract_end_at.strftime('%Y年%m月%d日')}），请提前30天书面通知续签意向或终止合同，避免形成无固定期限劳动合同的风险。"
)

employee1.comments.create!(
  author_name: hr_user1.display_name,
  author_role: "hr",
  content: "已安排与员工沟通续签事宜，员工表示愿意续签。"
)

employee2.comments.create!(
  author_name: "律师团队",
  author_role: "lawyer",
  content: "该员工档案完整，建议在合同到期前6个月进行续签意向调查。"
)

puts "📄 Creating contract records for #{company1.name}..."
# Create temp files for contract attachments
require 'tempfile'

temp_file1 = Tempfile.new(['contract', '.pdf'])
temp_file1.write("PDF placeholder content for steel purchase contract")
temp_file1.rewind

contract1 = company1.contracts.new(
  name: "钢材采购合同-广州钢铁厂",
  signed_at: 1.year.ago,
  end_at: 2.months.from_now,
  status: 'active'
)
contract1.file.attach(io: temp_file1, filename: 'steel_purchase_contract.pdf', content_type: 'application/pdf')
contract1.save!
temp_file1.close

temp_file2 = Tempfile.new(['contract', '.pdf'])
temp_file2.write("PDF placeholder content for equipment lease contract")
temp_file2.rewind

contract2 = company1.contracts.new(
  name: "设备租赁合同-深圳机械公司",
  signed_at: 3.months.ago,
  end_at: 9.months.from_now,
  status: 'active'
)
contract2.file.attach(io: temp_file2, filename: 'equipment_lease_contract.pdf', content_type: 'application/pdf')
contract2.save!
temp_file2.close

temp_file3 = Tempfile.new(['contract', '.pdf'])
temp_file3.write("PDF placeholder content for product sales contract")
temp_file3.rewind

contract3 = company1.contracts.new(
  name: "产品销售合同-惠州建筑公司",
  signed_at: 2.years.ago,
  end_at: 3.months.ago,
  status: 'completed'
)
contract3.file.attach(io: temp_file3, filename: 'product_sales_contract.pdf', content_type: 'application/pdf')
contract3.save!
temp_file3.close

puts "💬 Creating comments for contracts..."
contract1.comments.create!(
  author_name: "律师团队",
  author_role: "lawyer",
  content: "该合同即将到期，建议提前与对方沟通续签事宜。注意检查历史履约情况，若有违约记录建议调整合同条款。"
)

contract1.comments.create!(
  author_name: contract_user1.display_name,
  author_role: "contract",
  content: "已与对方负责人联系，对方表示愿意续签，价格条款需要重新商议。"
)

contract2.comments.create!(
  author_name: "律师团队",
  author_role: "lawyer",
  content: "合同条款完整，履行正常。建议保留每月租赁发票作为证据。"
)

puts "📘 Creating regulation records for #{company1.name}..."
temp_file4 = Tempfile.new(['regulation', '.pdf'])
temp_file4.write("PDF placeholder content for employee handbook 2024")
temp_file4.rewind

regulation1 = company1.regulations.new(
  name: "员工手册 2024版"
)
regulation1.file.attach(io: temp_file4, filename: 'employee_handbook_2024.pdf', content_type: 'application/pdf')
regulation1.save!
temp_file4.close

temp_file5 = Tempfile.new(['regulation', '.pdf'])
temp_file5.write("PDF placeholder content for salary management policy")
temp_file5.rewind

regulation2 = company1.regulations.new(
  name: "薪酬管理制度"
)
regulation2.file.attach(io: temp_file5, filename: 'salary_management_policy.pdf', content_type: 'application/pdf')
regulation2.save!
temp_file5.close

puts "💬 Creating comments for regulations..."
regulation1.comments.create!(
  author_name: "律师团队",
  author_role: "lawyer",
  content: "该员工手册符合《劳动合同法》要求，建议每年更新一次并组织全员签收确认。"
)

regulation1.comments.create!(
  author_name: hr_user1.display_name,
  author_role: "hr",
  content: "已安排全体员工签收，签收回执已存档。"
)

regulation2.comments.create!(
  author_name: "律师团队",
  author_role: "lawyer",
  content: "薪酬制度需补充加班工资计算方式，建议参考《劳动法》第44条规定明确各类加班的工资倍数。"
)

puts "📋 Creating some data for #{company2.name}..."
employee4 = company2.employees.create!(
  name: "赵六",
  gender: "男",
  id_number: "440201199010101234",
  position: "销售经理",
  salary: 10000,
  hired_at: 3.years.ago,
  probation_end_at: 3.years.ago + 3.months,
  social_insurance_at: 3.years.ago,
  contract_signed_at: 3.years.ago,
  contract_end_at: 2.years.from_now
)

temp_file6 = Tempfile.new(['contract', '.pdf'])
temp_file6.write("PDF placeholder content for building materials supply contract")
temp_file6.rewind

contract4 = company2.contracts.new(
  name: "建材供应合同-广州房地产公司",
  signed_at: 6.months.ago,
  end_at: 1.year.from_now + 6.months,
  status: 'active'
)
contract4.file.attach(io: temp_file6, filename: 'building_materials_supply.pdf', content_type: 'application/pdf')
contract4.save!
temp_file6.close

puts "\n✅ Seed data created successfully!"
puts "\n📊 Summary:"
puts "- Companies: #{Company.count}"
puts "- Lawyer Accounts: #{LawyerAccount.count}"
puts "- Company Users: #{CompanyUser.count}"
puts "- Employees: #{Employee.count}"
puts "- Contracts: #{Contract.count}"
puts "- Regulations: #{Regulation.count}"
puts "- Comments: #{Comment.count}"

puts "\n🔑 Login Credentials:"
puts "\n律师账号:"
puts "Email: liang@lawyer.com"
puts "Password: password123"

puts "\n#{company1.name} - 人事账号:"
puts "Email: hr@foshan-metal.com"
puts "Password: password123"

puts "\n#{company1.name} - 合同账号:"
puts "Email: contract@foshan-metal.com"
puts "Password: password123"

puts "\n#{company2.name} - 人事账号:"
puts "Email: hr@dongguan-building.com"
puts "Password: password123"
