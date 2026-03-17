namespace :search do
  desc "重建所有搜索索引"
  task rebuild: :environment do
    puts "正在重建搜索索引..."
    
    SearchIndex.delete_all
    puts "✓ 已清空旧索引"
    
    models = [Contract, Case, MajorIssue, Reconciliation, WorkLog]
    total_count = 0
    
    models.each do |model|
      print "正在索引 #{model.name}..."
      count = 0
      
      model.find_each do |record|
        begin
          record.update_search_index
          count += 1
        rescue => e
          puts "\n✗ 索引失败: #{model.name}##{record.id} - #{e.message}"
        end
      end
      
      total_count += count
      puts " ✓ 完成 (#{count} 条)"
    end
    
    puts "\n✅ 搜索索引重建完成！共索引 #{total_count} 条记录"
  end
  
  desc "显示搜索索引统计"
  task stats: :environment do
    puts "\n搜索索引统计："
    puts "=" * 50
    
    SearchIndex.group(:category).count.each do |category, count|
      puts "#{category.ljust(20)} #{count} 条"
    end
    
    puts "=" * 50
    puts "总计：#{SearchIndex.count} 条"
  end
end
