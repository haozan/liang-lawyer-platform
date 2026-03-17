import { Application } from "@hotwired/stimulus"

import ThemeController from "./theme_controller"
import DropdownController from "./dropdown_controller"
import SdkIntegrationController from "./sdk_integration_controller"
import ClipboardController from "./clipboard_controller"
import TomSelectController from "./tom_select_controller"
import FlatpickrController from "./flatpickr_controller"
import SystemMonitorController from "./system_monitor_controller"
import FlashController from "./flash_controller"
import ScrollRevealController from "./scroll_reveal_controller"
import LoginTabController from "./login_tab_controller"
import ImagePreviewController from "./image_preview_controller"
import FileDeleteController from "./file_delete_controller"
import MentionSelectController from "./mention_select_controller"
import FloatingSearchController from "./floating_search_controller"
import SearchShortcutController from "./search_shortcut_controller"
import PdfViewerController from "./pdf_viewer_controller"
import HorizontalScrollController from "./horizontal_scroll_controller"
import AnnouncementToggleController from "./announcement_toggle_controller"
import CaseTeamController from "./case_team_controller"
import CompanySelectorController from "./company_selector_controller"
import AppealCalculatorController from "./appeal_calculator_controller"
import ReconciliationCycleController from "./reconciliation_cycle_controller"
import AnnouncementGroupToggleController from "./announcement_group_toggle_controller"
import TabsController from "./tabs_controller"
import CollapsibleController from "./collapsible_controller"
import MajorIssueController from "./major_issue_controller"
import AnalyticsQuickNavController from "./analytics_quick_nav_controller"
import WorkbenchExpiryController from "./workbench_expiry_controller"
import ContractCalendarController from "./contract_calendar_controller"
import FilterPanelController from "./filter_panel_controller"
import CaseTabsController from "./case_tabs_controller"
import CaseClientsController from "./case_clients_controller"
import ClaimsManagerController from "./claims_manager_controller"
import CaseRelationsController from "./case_relations_controller"
import CaseStatusToggleController from "./case_status_toggle_controller"
import WechatModalController from "./wechat_modal_controller"
import DashboardChartController from "./dashboard_chart_controller"
import AnalyticsStickyBarController from "./analytics_sticky_bar_controller"
import StatusIndicatorController from "./status_indicator_controller"
import PendingTasksController from "./pending_tasks_controller"
import WordViewerController from "./word_viewer_controller"

const application = Application.start()

application.register("theme", ThemeController)
application.register("dropdown", DropdownController)
application.register("sdk-integration", SdkIntegrationController)
application.register("clipboard", ClipboardController)
application.register("tom-select", TomSelectController)
application.register("flatpickr", FlatpickrController)
application.register("system-monitor", SystemMonitorController)
application.register("flash", FlashController)
application.register("scroll-reveal", ScrollRevealController)
application.register("login-tab", LoginTabController)
application.register("image-preview", ImagePreviewController)
application.register("file-delete", FileDeleteController)
application.register("mention-select", MentionSelectController)
application.register("floating-search", FloatingSearchController)
application.register("search-shortcut", SearchShortcutController)
application.register("pdf-viewer", PdfViewerController)
application.register("horizontal-scroll", HorizontalScrollController)
application.register("announcement-toggle", AnnouncementToggleController)
application.register("case-team", CaseTeamController)
application.register("company-selector", CompanySelectorController)
application.register("appeal-calculator", AppealCalculatorController)
application.register("reconciliation-cycle", ReconciliationCycleController)
application.register("announcement-group-toggle", AnnouncementGroupToggleController)
application.register("tabs", TabsController)
application.register("collapsible", CollapsibleController)
application.register("major-issue", MajorIssueController)
application.register("analytics-quick-nav", AnalyticsQuickNavController)
application.register("workbench-expiry", WorkbenchExpiryController)
application.register("contract-calendar", ContractCalendarController)
application.register("filter-panel", FilterPanelController)
application.register("case-tabs", CaseTabsController)
application.register("case-clients", CaseClientsController)
application.register("claims-manager", ClaimsManagerController)
application.register("case-relations", CaseRelationsController)
application.register("case-status-toggle", CaseStatusToggleController)
application.register("wechat-modal", WechatModalController)
application.register("dashboard-chart", DashboardChartController)
application.register("analytics-sticky-bar", AnalyticsStickyBarController)
application.register("status-indicator", StatusIndicatorController)
application.register("pending-tasks", PendingTasksController)
application.register("word-viewer", WordViewerController)

window.Stimulus = application
