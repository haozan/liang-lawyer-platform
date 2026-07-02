class Comment < ApplicationRecord
  # === 关联 ===
  belongs_to :commentable, polymorphic: true
  belongs_to :author, polymorphic: true, optional: true
  has_many_attached :attachments

  # === 验证 ===
  validates :author_name, presence: true
  validates :author_role, presence: true, inclusion: { in: %w[lawyer company_user] }
  validates :content, presence: true

  # === Scopes ===
  scope :ordered, -> { order(created_at: :asc) }

  # === 显示方法 ===
  def lawyer_comment?
    author_role == 'lawyer'
  end

  def company_user_comment?
    author_role == 'company_user'
  end

  def author_display
    if lawyer_comment?
      "#{author_name}（律师）"
    else
      author_name
    end
  end

  def time_display
    created_at.strftime('%Y-%m-%d %H:%M')
  end
end
