Rails.application.routes.draw do
  # Root path - redirect based on user type
  root "home#index"

  # === 认证 ===
  resource :session, only: [:new, :create, :destroy]
  get  "login",          to: "sessions#new",            as: :login
  post "login",          to: "sessions#create"
  delete "logout",       to: "sessions#destroy",         as: :logout
  get  "select_company", to: "sessions#select_company",  as: :select_company
  post "enter_company",  to: "sessions#enter_company",   as: :enter_company

  # Account unlock
  get "unlock_account/:token", to: "account_unlocks#show", as: :unlock_account

  # === 合同管理 ===
  resources :contracts do
    member do
      post :mark_as_reviewed
    end
    resources :reconciliations, only: [:create, :destroy] do
      member do
        post :mark_as_reviewed
      end
      resources :comments, only: [:create], controller: "comments"
    end
    resources :comments, only: [:create], controller: "comments"
  end

  # === 案件管理 ===
  resources :cases do
    resources :work_logs, only: [:index, :create, :update, :destroy]
    resources :comments, only: [:create, :update, :destroy], controller: "comments"
    member do
      post :append_attachments
    end
  end

  # === 重大事项 ===
  resources :major_issues do
    resources :comments, only: [:create, :update, :destroy], controller: "comments"
    member do
      post :resolve
    end
  end

  # === 公告（前台） ===
  resources :announcements, only: [:index]

  # === 评论通用操作 ===
  resources :comments, only: [:update, :destroy]

  # === 对账单评论 ===
  resources :reconciliations, only: [] do
    resources :comments, only: [:create], controller: "comments"
  end

  # === 律师选择企业 ===
  namespace :lawyer do
    resources :companies, only: [:index] do
      member do
        post :enter
      end
    end
    resource :profile, only: [:edit, :update]
  end

  # === 附件安全访问 ===
  get "/secure/blobs/:signed_id/*filename", to: "secure_blobs#show", as: :secure_blob, defaults: { disposition: "inline" }
  get "/secure/blobs/:signed_id/*filename/download", to: "secure_blobs#show", as: :secure_blob_download, defaults: { disposition: "attachment" }
  delete "attachments/:id", to: "attachments#destroy", as: :attachment

  # === Profile ===
  resource :profile, only: [:edit, :update]

  # === 后台管理 ===
  namespace :admin do
    root "dashboard#index"

    # 企业管理
    resources :companies do
      member do
        post :suspend
        post :resume
      end
    end

    # 律师账号管理
    resources :lawyer_accounts do
      member do
        post :toggle_status
      end
    end

    # 企业用户管理
    resources :company_users do
      member do
        post :toggle_status
      end
    end

    # 公告管理
    resources :announcements

    # 管理员登录
    resource :session, only: [:new, :create, :destroy]
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout
  end

  # === GoodJob 定时任务 ===
  mount GoodJob::Engine => "/admin/good_job", as: :admin_good_job

  # === 健康检查 ===
  get "up", to: "rails/health#show", as: :rails_health_check

  # Demo routes (development only)
  if Rails.env.development?
    get "design_demo", to: "sessions#design_demo"
  end
end
