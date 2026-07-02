# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_04_15_150757) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_oplogs", force: :cascade do |t|
    t.bigint "administrator_id", null: false
    t.string "action"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "ip_address"
    t.text "user_agent"
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_admin_oplogs_on_action"
    t.index ["administrator_id"], name: "index_admin_oplogs_on_administrator_id"
    t.index ["created_at"], name: "index_admin_oplogs_on_created_at"
    t.index ["resource_type", "resource_id"], name: "index_admin_oplogs_on_resource_type_and_resource_id"
  end

  create_table "administrators", force: :cascade do |t|
    t.string "name", null: false
    t.string "password_digest"
    t.string "role", null: false
    t.boolean "first_login", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone", null: false
    t.index ["name"], name: "index_administrators_on_name", unique: true
    t.index ["phone"], name: "index_administrators_on_phone", unique: true
    t.index ["role"], name: "index_administrators_on_role"
  end

  create_table "announcement_dismissals", force: :cascade do |t|
    t.string "announcement_type", null: false
    t.string "related_type", null: false
    t.bigint "related_id", null: false
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.string "dismissal_reason"
    t.datetime "dismissed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_type", "related_type", "related_id"], name: "idx_dismissal_lookup"
    t.index ["related_type", "related_id"], name: "index_announcement_dismissals_on_related"
    t.index ["user_type", "user_id"], name: "index_announcement_dismissals_on_user"
    t.index ["user_type", "user_id"], name: "index_announcement_dismissals_on_user_type_and_user_id"
  end

  create_table "announcement_groups", force: :cascade do |t|
    t.string "group_key", null: false
    t.string "group_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "icon"
    t.string "color_class"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_key"], name: "index_announcement_groups_on_group_key", unique: true
  end

  create_table "announcement_read_statuses", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.datetime "read_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id", "user_type", "user_id"], name: "index_announcement_read_unique", unique: true
    t.index ["announcement_id"], name: "index_announcement_read_statuses_on_announcement_id"
    t.index ["user_type", "user_id"], name: "index_announcement_read_statuses_on_user_type_and_user_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.string "announcement_type", null: false
    t.string "priority", default: "normal", null: false
    t.bigint "company_id"
    t.string "related_type"
    t.bigint "related_id"
    t.datetime "expires_at"
    t.datetime "published_at"
    t.string "created_by_type"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_type"], name: "index_announcements_on_announcement_type"
    t.index ["company_id", "published_at", "announcement_type"], name: "idx_announcements_company_published_type"
    t.index ["company_id"], name: "index_announcements_on_company_id"
    t.index ["priority"], name: "index_announcements_on_priority"
    t.index ["published_at"], name: "index_announcements_on_published_at"
    t.index ["related_type", "related_id"], name: "index_announcements_on_related_type_and_related_id"
  end

  create_table "case_clients", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.bigint "company_id", null: false
    t.string "role", default: "client"
    t.integer "position", default: 0
    t.date "joined_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id", "company_id"], name: "index_case_clients_on_case_id_and_company_id", unique: true
    t.index ["case_id"], name: "index_case_clients_on_case_id"
    t.index ["company_id"], name: "index_case_clients_on_company_id"
    t.index ["position"], name: "index_case_clients_on_position"
    t.index ["role"], name: "index_case_clients_on_role"
  end

  create_table "case_filters", force: :cascade do |t|
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.jsonb "filter_params", default: {}
    t.boolean "is_default", default: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_case_filters_on_position"
    t.index ["user_type", "user_id", "is_default"], name: "index_case_filters_on_user_type_and_user_id_and_is_default"
    t.index ["user_type", "user_id"], name: "index_case_filters_on_user"
  end

  create_table "case_notifications", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.string "notification_type", null: false
    t.string "title"
    t.text "content"
    t.jsonb "metadata", default: {}
    t.datetime "read_at"
    t.datetime "sent_at"
    t.boolean "email_sent", default: false
    t.boolean "sms_sent", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_case_notifications_on_case_id"
    t.index ["notification_type"], name: "index_case_notifications_on_notification_type"
    t.index ["read_at"], name: "index_case_notifications_on_read_at"
    t.index ["recipient_type", "recipient_id", "read_at"], name: "idx_case_notifications_recipient_read"
    t.index ["recipient_type", "recipient_id"], name: "index_case_notifications_on_recipient"
    t.index ["sent_at"], name: "index_case_notifications_on_sent_at"
  end

  create_table "case_progress_events", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.string "event_type", null: false
    t.string "title", null: false
    t.text "description"
    t.date "event_date", null: false
    t.datetime "event_time"
    t.jsonb "metadata", default: {}
    t.boolean "is_milestone", default: false
    t.boolean "is_automated", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_case_progress_events_on_case_id"
    t.index ["event_date"], name: "index_case_progress_events_on_event_date"
    t.index ["event_type"], name: "index_case_progress_events_on_event_type"
    t.index ["is_milestone"], name: "index_case_progress_events_on_is_milestone"
  end

  create_table "case_questions", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.string "asker_type", null: false
    t.bigint "asker_id", null: false
    t.text "question", null: false
    t.text "answer"
    t.string "answerer_type"
    t.bigint "answerer_id"
    t.datetime "answered_at"
    t.boolean "is_resolved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answered_at"], name: "index_case_questions_on_answered_at"
    t.index ["answerer_type", "answerer_id"], name: "index_case_questions_on_answerer"
    t.index ["asker_type", "asker_id"], name: "index_case_questions_on_asker"
    t.index ["case_id"], name: "index_case_questions_on_case_id"
    t.index ["is_resolved"], name: "index_case_questions_on_is_resolved"
  end

  create_table "case_relations", force: :cascade do |t|
    t.bigint "from_case_id", null: false
    t.bigint "to_case_id", null: false
    t.string "relation_type", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_case_id", "to_case_id"], name: "index_case_relations_on_from_case_id_and_to_case_id", unique: true
    t.index ["relation_type"], name: "index_case_relations_on_relation_type"
  end

  create_table "case_series", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "company_id", null: false
    t.string "created_by_type"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_case_series_on_company_id"
    t.index ["created_by_type", "created_by_id"], name: "index_case_series_on_created_by"
  end

  create_table "case_series_memberships", force: :cascade do |t|
    t.bigint "case_series_id", null: false
    t.bigint "case_id", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_case_series_memberships_on_case_id"
    t.index ["case_series_id", "case_id"], name: "index_case_series_memberships_on_case_series_id_and_case_id", unique: true
    t.index ["case_series_id"], name: "index_case_series_memberships_on_case_series_id"
  end

  create_table "case_team_members", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.bigint "lawyer_account_id", null: false
    t.string "role", null: false
    t.datetime "joined_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id", "lawyer_account_id"], name: "index_case_team_on_case_and_lawyer", unique: true
    t.index ["case_id"], name: "index_case_team_members_on_case_id"
    t.index ["lawyer_account_id", "case_id"], name: "idx_case_team_lawyer_case", where: "(lawyer_account_id IS NOT NULL)"
    t.index ["lawyer_account_id"], name: "index_case_team_members_on_lawyer_account_id"
    t.index ["role"], name: "index_case_team_members_on_role"
  end

  create_table "case_weekly_reports", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.date "week_start_date", null: false
    t.date "week_end_date", null: false
    t.jsonb "work_summary", default: {}
    t.jsonb "next_week_plan", default: {}
    t.text "lawyer_assessment"
    t.datetime "generated_at"
    t.boolean "is_auto_generated", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id", "week_start_date"], name: "index_case_weekly_reports_on_case_id_and_week_start_date", unique: true
    t.index ["case_id"], name: "index_case_weekly_reports_on_case_id"
    t.index ["week_end_date"], name: "index_case_weekly_reports_on_week_end_date"
    t.index ["week_start_date"], name: "index_case_weekly_reports_on_week_start_date"
  end

  create_table "cases", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "case_number"
    t.string "case_type"
    t.string "court_name"
    t.string "status", default: "pending"
    t.date "filing_at"
    t.datetime "hearing_at"
    t.date "judgement_received_at"
    t.date "archived_at"
    t.date "closing_at"
    t.text "summary"
    t.integer "deleted_by_employee_id"
    t.datetime "deletion_requested_at"
    t.integer "confirmed_by_boss_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stage"
    t.date "appeal_deadline_date"
    t.date "property_preservation_applied_at"
    t.date "property_preservation_deadline"
    t.jsonb "property_preservation_history"
    t.string "priority", default: "normal"
    t.date "estimated_end_date"
    t.string "tags", default: [], array: true
    t.datetime "last_activity_at"
    t.string "our_party_role"
    t.string "counterparty_role"
    t.decimal "claim_amount", precision: 15, scale: 2, comment: "诉讼标的额"
    t.decimal "awarded_amount", precision: 15, scale: 2, comment: "判决/调解金额"
    t.decimal "litigation_fee", precision: 15, scale: 2, comment: "诉讼费"
    t.decimal "lawyer_fee", precision: 15, scale: 2, comment: "律师费"
    t.string "amount_status", comment: "金额状态: pending(待判决), awarded(已判决), paid(已支付), partial_paid(部分支付)"
    t.string "our_party_name", comment: "我方当事人名称"
    t.string "counterparty_name", comment: "对方当事人名称"
    t.string "counterparty_lawyer", comment: "对方代理律师"
    t.string "counterparty_lawfirm", comment: "对方律师事务所"
    t.string "counterparty_contact", comment: "对方联系方式"
    t.jsonb "third_parties", comment: "第三人信息（JSON格式）"
    t.jsonb "claims", comment: "诉讼请求（JSON数组）"
    t.jsonb "judgement_result", comment: "判决结果（JSON数组）"
    t.string "case_outcome", comment: "案件结局: total_win(全胜), partial_win(部分胜诉), lose(败诉), settled(调解), withdrawn(撤诉)"
    t.date "execution_start_at", comment: "执行立案日期"
    t.date "execution_deadline", comment: "执行期限"
    t.jsonb "execution_measures", comment: "执行措施（JSON数组）"
    t.decimal "executed_amount", precision: 15, scale: 2, comment: "已执行金额"
    t.string "execution_status", comment: "执行状态: executing(执行中), terminated(终本), settled(和解执行), completed(执行完毕)"
    t.text "execution_notes", comment: "执行备注"
    t.string "judge_name"
    t.string "judge_phone"
    t.string "clerk_name"
    t.string "clerk_phone"
    t.text "lawyer_fee_payment_terms"
    t.decimal "lawyer_fee_received", precision: 15, scale: 2, comment: "律师费已回款金额"
    t.date "lawyer_fee_received_at", comment: "律师费回款日期"
    t.string "lawyer_fee_payment_status", default: "pending", comment: "律师费付款状态: pending(待付款), partial(部分付款), completed(已付清)"
    t.boolean "lawyer_fee_invoice_issued", default: false, comment: "律师费是否已开发票"
    t.string "lawyer_fee_invoice_number", comment: "律师费发票号码"
    t.date "lawyer_fee_invoice_issued_at", comment: "律师费开票日期"
    t.decimal "lawyer_fee_invoice_amount", precision: 15, scale: 2, comment: "律师费开票金额"
    t.index ["amount_status"], name: "index_cases_on_amount_status"
    t.index ["appeal_deadline_date"], name: "index_cases_on_appeal_deadline_date"
    t.index ["case_number"], name: "index_cases_on_case_number"
    t.index ["case_outcome"], name: "index_cases_on_case_outcome"
    t.index ["claim_amount"], name: "index_cases_on_claim_amount"
    t.index ["company_id", "priority", "last_activity_at"], name: "idx_cases_company_priority_activity"
    t.index ["company_id", "status", "filing_at"], name: "idx_cases_company_status_filing"
    t.index ["company_id"], name: "index_cases_on_company_id"
    t.index ["counterparty_name"], name: "index_cases_on_counterparty_name"
    t.index ["deleted_at"], name: "index_cases_on_deleted_at"
    t.index ["execution_start_at"], name: "index_cases_on_execution_start_at"
    t.index ["execution_status"], name: "index_cases_on_execution_status"
    t.index ["last_activity_at"], name: "index_cases_on_last_activity_at"
    t.index ["lawyer_fee_invoice_issued"], name: "index_cases_on_lawyer_fee_invoice_issued"
    t.index ["lawyer_fee_invoice_number"], name: "index_cases_on_lawyer_fee_invoice_number"
    t.index ["lawyer_fee_payment_status"], name: "index_cases_on_lawyer_fee_payment_status"
    t.index ["lawyer_fee_received_at"], name: "index_cases_on_lawyer_fee_received_at"
    t.index ["our_party_name"], name: "index_cases_on_our_party_name"
    t.index ["priority"], name: "index_cases_on_priority"
    t.index ["stage"], name: "index_cases_on_stage"
    t.index ["status"], name: "index_cases_on_status"
    t.index ["tags"], name: "index_cases_on_tags", using: :gin
  end

  create_table "comments", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.string "author_name"
    t.string "author_role"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "review_status", default: "approved"
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.integer "author_id"
    t.string "author_type"
    t.jsonb "mentioned_user_ids", default: []
    t.boolean "is_pinned", default: false
    t.datetime "pinned_at"
    t.integer "pinned_by_id"
    t.string "pinned_by_type"
    t.boolean "is_key_opinion", default: false
    t.string "visibility", default: "public", null: false
    t.index ["author_type", "author_id"], name: "index_comments_on_author_type_and_author_id"
    t.index ["commentable_type", "commentable_id", "created_at"], name: "idx_comments_polymorphic_created"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["is_key_opinion"], name: "index_comments_on_is_key_opinion"
    t.index ["is_pinned"], name: "index_comments_on_is_pinned"
    t.index ["mentioned_user_ids"], name: "index_comments_on_mentioned_user_ids", using: :gin
    t.index ["pinned_by_type", "pinned_by_id"], name: "index_comments_on_pinned_by_type_and_pinned_by_id"
    t.index ["review_status"], name: "index_comments_on_review_status"
    t.index ["reviewed_by_id"], name: "index_comments_on_reviewed_by_id"
    t.index ["visibility"], name: "index_comments_on_visibility"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "active", null: false
    t.date "service_expires_at"
    t.datetime "suspended_at"
    t.text "suspended_reason"
    t.integer "assigned_lawyer_ids", default: [], array: true
    t.index ["assigned_lawyer_ids"], name: "index_companies_on_assigned_lawyer_ids", using: :gin
    t.index ["service_expires_at"], name: "index_companies_on_service_expires_at"
    t.index ["status"], name: "index_companies_on_status"
  end

  create_table "company_memberships", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "company_user_id", null: false
    t.string "role", default: "employee", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "company_user_id"], name: "index_company_memberships_unique", unique: true
    t.index ["company_id"], name: "index_company_memberships_on_company_id"
    t.index ["company_user_id"], name: "index_company_memberships_on_company_user_id"
  end

  create_table "company_users", force: :cascade do |t|
    t.string "password_digest"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["phone"], name: "index_company_users_on_phone", unique: true
    t.index ["unlock_token"], name: "index_company_users_on_unlock_token", unique: true
  end

  create_table "contract_taggings", force: :cascade do |t|
    t.integer "contract_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contract_tags", force: :cascade do |t|
    t.string "name"
    t.string "color", default: "#3B82F6"
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contracts", force: :cascade do |t|
    t.bigint "company_id"
    t.string "name"
    t.date "signed_at"
    t.date "end_at"
    t.string "status", default: "active"
    t.string "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reviewed_by_lawyer", default: false
    t.datetime "last_lawyer_comment_at"
    t.integer "reconciliation_cycle_days"
    t.string "our_party_role"
    t.string "our_signatory"
    t.string "our_signatory_title"
    t.string "counterparty_name"
    t.string "counterparty_role"
    t.string "counterparty_type"
    t.string "counterparty_unified_code"
    t.string "counterparty_legal_rep"
    t.string "counterparty_address"
    t.string "counterparty_contact"
    t.string "counterparty_phone"
    t.string "contract_number"
    t.string "contract_title"
    t.string "contract_type"
    t.string "signing_location"
    t.decimal "contract_amount", precision: 15, scale: 2
    t.string "currency", default: "人民币"
    t.string "amount_in_words"
    t.string "payment_method"
    t.text "payment_terms"
    t.date "performance_start_date"
    t.date "performance_end_date"
    t.date "delivery_date"
    t.string "delivery_location"
    t.date "acceptance_date"
    t.string "warranty_period"
    t.date "warranty_end_date"
    t.text "penalty_clause"
    t.decimal "liquidated_damages", precision: 15, scale: 2
    t.string "dispute_resolution"
    t.string "arbitration_institution"
    t.string "jurisdiction_court"
    t.string "applicable_law"
    t.string "legal_review_status", default: "待审查"
    t.string "legal_risk_level"
    t.text "legal_risk_summary"
    t.text "lawyer_suggestions"
    t.string "reviewed_by_lawyer_name"
    t.datetime "reviewed_at_lawyer"
    t.string "performance_status", default: "未开始履行"
    t.integer "performance_progress", default: 0
    t.text "performance_notes"
    t.date "last_contact_date"
    t.date "next_follow_up_date"
    t.boolean "has_supplement", default: false
    t.integer "supplement_count", default: 0
    t.date "last_supplement_date"
    t.boolean "has_modification", default: false
    t.text "modification_summary"
    t.string "dispute_status", default: "无争议"
    t.date "dispute_occurred_at"
    t.integer "related_case_id"
    t.decimal "litigation_amount", precision: 15, scale: 2
    t.text "litigation_notes"
    t.date "case_closed_at"
    t.boolean "auto_renewal", default: false
    t.integer "renewal_notice_period"
    t.integer "renewal_times", default: 0
    t.date "last_renewal_date"
    t.string "renewal_intention"
    t.text "renewal_notes"
    t.string "client_contact"
    t.string "client_contact_phone"
    t.string "client_dept"
    t.integer "assigned_lawyer_id"
    t.integer "assistant_lawyer_ids", default: [], array: true
    t.text "internal_notes"
    t.index ["assigned_lawyer_id"], name: "index_contracts_on_assigned_lawyer_id"
    t.index ["company_id", "end_at"], name: "idx_contracts_company_end_at"
    t.index ["company_id", "status", "signed_at"], name: "idx_contracts_company_status_signed"
    t.index ["company_id"], name: "index_contracts_on_company_id"
    t.index ["contract_number"], name: "index_contracts_on_contract_number"
    t.index ["contract_type"], name: "index_contracts_on_contract_type"
    t.index ["counterparty_name"], name: "index_contracts_on_counterparty_name"
    t.index ["dispute_status"], name: "index_contracts_on_dispute_status"
    t.index ["legal_risk_level"], name: "index_contracts_on_legal_risk_level"
    t.index ["performance_status"], name: "index_contracts_on_performance_status"
    t.index ["related_case_id"], name: "index_contracts_on_related_case_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "lawyer_accounts", force: :cascade do |t|
    t.string "password_digest"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "lawyer"
    t.string "phone"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["phone"], name: "index_lawyer_accounts_on_phone", unique: true
    t.index ["role"], name: "index_lawyer_accounts_on_role"
    t.index ["unlock_token"], name: "index_lawyer_accounts_on_unlock_token", unique: true
  end

  create_table "major_issue_followers", force: :cascade do |t|
    t.bigint "major_issue_id", null: false
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.boolean "notify_new_comment", default: true
    t.boolean "notify_status_change", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["major_issue_id", "user_type", "user_id"], name: "index_followers_on_issue_and_user", unique: true
    t.index ["major_issue_id"], name: "index_major_issue_followers_on_major_issue_id"
    t.index ["user_type", "user_id"], name: "index_major_issue_followers_on_user"
  end

  create_table "major_issue_read_statuses", force: :cascade do |t|
    t.bigint "major_issue_id", null: false
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.datetime "last_read_at"
    t.integer "last_read_comment_id"
    t.integer "unread_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["major_issue_id", "user_type", "user_id"], name: "index_read_statuses_on_issue_and_user", unique: true
    t.index ["major_issue_id"], name: "index_major_issue_read_statuses_on_major_issue_id"
    t.index ["unread_count"], name: "index_major_issue_read_statuses_on_unread_count"
    t.index ["user_type", "user_id"], name: "index_major_issue_read_statuses_on_user"
  end

  create_table "major_issue_todo_items", force: :cascade do |t|
    t.bigint "major_issue_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "pending"
    t.string "assignee_type"
    t.bigint "assignee_id"
    t.string "creator_type"
    t.bigint "creator_id"
    t.date "due_date"
    t.datetime "completed_at"
    t.integer "completed_by_id"
    t.string "completed_by_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_type", "assignee_id"], name: "index_major_issue_todo_items_on_assignee"
    t.index ["completed_by_type", "completed_by_id"], name: "idx_on_completed_by_type_completed_by_id_9985adfab5"
    t.index ["creator_type", "creator_id"], name: "index_major_issue_todo_items_on_creator"
    t.index ["due_date"], name: "index_major_issue_todo_items_on_due_date"
    t.index ["major_issue_id"], name: "index_major_issue_todo_items_on_major_issue_id"
    t.index ["status"], name: "index_major_issue_todo_items_on_status"
  end

  create_table "major_issues", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "title"
    t.string "issue_type"
    t.string "priority", default: "medium"
    t.string "status", default: "pending"
    t.text "description"
    t.date "resolved_at"
    t.integer "mentioned_lawyer_id"
    t.integer "deleted_by_employee_id"
    t.datetime "deletion_requested_at"
    t.integer "confirmed_by_boss_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reviewed_by_lawyer", default: false
    t.datetime "reviewed_at"
    t.integer "reviewed_by_lawyer_id"
    t.text "conclusion"
    t.integer "processing_days", default: 0
    t.integer "followers_count", default: 0
    t.integer "views_count", default: 0
    t.integer "comments_count", default: 0
    t.string "related_record_type"
    t.integer "related_record_id"
    t.string "share_token"
    t.datetime "share_expires_at"
    t.datetime "discussing_at"
    t.datetime "archived_at"
    t.datetime "conclusion_updated_at"
    t.integer "conclusion_updated_by_id"
    t.string "conclusion_updated_by_type"
    t.text "team_member_ids"
    t.index ["company_id", "created_at"], name: "idx_major_issues_company_created_at"
    t.index ["company_id", "status", "priority"], name: "idx_major_issues_company_status_priority"
    t.index ["company_id"], name: "index_major_issues_on_company_id"
    t.index ["conclusion_updated_by_type", "conclusion_updated_by_id"], name: "index_major_issues_on_conclusion_updater"
    t.index ["deleted_at"], name: "index_major_issues_on_deleted_at"
    t.index ["mentioned_lawyer_id"], name: "index_major_issues_on_mentioned_lawyer_id"
    t.index ["priority"], name: "index_major_issues_on_priority"
    t.index ["processing_days"], name: "index_major_issues_on_processing_days"
    t.index ["related_record_type", "related_record_id"], name: "idx_on_related_record_type_related_record_id_e914562c64"
    t.index ["reviewed_by_lawyer"], name: "index_major_issues_on_reviewed_by_lawyer"
    t.index ["reviewed_by_lawyer_id"], name: "index_major_issues_on_reviewed_by_lawyer_id"
    t.index ["share_token"], name: "index_major_issues_on_share_token", unique: true
    t.index ["status"], name: "index_major_issues_on_status"
    t.index ["team_member_ids"], name: "index_major_issues_on_team_member_ids"
  end

  create_table "reconciliations", force: :cascade do |t|
    t.bigint "contract_id"
    t.string "period"
    t.string "uploaded_by"
    t.datetime "uploaded_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "mentioned_users"
    t.boolean "reviewed_by_lawyer", default: false
    t.datetime "reviewed_at"
    t.integer "reviewed_by_lawyer_id"
    t.index ["contract_id"], name: "index_reconciliations_on_contract_id"
    t.index ["reviewed_by_lawyer"], name: "index_reconciliations_on_reviewed_by_lawyer"
    t.index ["reviewed_by_lawyer_id"], name: "index_reconciliations_on_reviewed_by_lawyer_id"
  end

  create_table "saved_filters", force: :cascade do |t|
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.jsonb "conditions", default: {}
    t.string "filterable_type", null: false
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conditions"], name: "index_saved_filters_on_conditions", using: :gin
    t.index ["is_default"], name: "index_saved_filters_on_is_default"
    t.index ["user_type", "user_id", "filterable_type"], name: "index_saved_filters_on_user_and_type"
    t.index ["user_type", "user_id"], name: "index_saved_filters_on_user"
  end

  create_table "search_indexes", force: :cascade do |t|
    t.string "searchable_type", null: false
    t.bigint "searchable_id", null: false
    t.bigint "company_id", null: false
    t.string "title", null: false
    t.text "content"
    t.string "category"
    t.jsonb "metadata", default: {}
    t.datetime "indexed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_search_indexes_on_category"
    t.index ["company_id"], name: "index_search_indexes_on_company_id"
    t.index ["content"], name: "index_search_indexes_on_content", opclass: :gin_trgm_ops, using: :gin
    t.index ["searchable_type", "searchable_id"], name: "index_search_on_searchable", unique: true
    t.index ["title"], name: "index_search_indexes_on_title", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "work_logs", force: :cascade do |t|
    t.bigint "case_id"
    t.date "date"
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "submitter_type"
    t.bigint "submitter_id"
    t.string "log_type", default: "general"
    t.boolean "is_todo", default: false
    t.string "todo_status"
    t.date "due_date"
    t.datetime "reminder_at"
    t.datetime "completed_at"
    t.boolean "is_important", default: false
    t.integer "assigned_to_id"
    t.string "assigned_to_type"
    t.index ["assigned_to_type", "assigned_to_id"], name: "index_work_logs_on_assigned_to_type_and_assigned_to_id"
    t.index ["case_id"], name: "index_work_logs_on_case_id"
    t.index ["due_date"], name: "index_work_logs_on_due_date"
    t.index ["is_todo"], name: "index_work_logs_on_is_todo"
    t.index ["log_type"], name: "index_work_logs_on_log_type"
    t.index ["submitter_type", "submitter_id"], name: "index_work_logs_on_submitter"
    t.index ["todo_status"], name: "index_work_logs_on_todo_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_oplogs", "administrators"
  add_foreign_key "case_clients", "cases"
  add_foreign_key "case_clients", "companies"
  add_foreign_key "case_notifications", "cases"
  add_foreign_key "case_progress_events", "cases"
  add_foreign_key "case_questions", "cases"
  add_foreign_key "case_relations", "cases", column: "from_case_id"
  add_foreign_key "case_relations", "cases", column: "to_case_id"
  add_foreign_key "case_series", "companies"
  add_foreign_key "case_series_memberships", "case_series"
  add_foreign_key "case_series_memberships", "cases"
  add_foreign_key "case_team_members", "cases"
  add_foreign_key "case_team_members", "lawyer_accounts"
  add_foreign_key "case_weekly_reports", "cases"
  add_foreign_key "cases", "companies"
  add_foreign_key "company_memberships", "companies"
  add_foreign_key "company_memberships", "company_users"
  add_foreign_key "major_issue_followers", "major_issues"
  add_foreign_key "major_issue_read_statuses", "major_issues"
  add_foreign_key "major_issue_todo_items", "major_issues"
  add_foreign_key "major_issues", "companies"
end
