import { Controller } from "@hotwired/stimulus"

/**
 * Tabs Controller
 * 
 * Manages tab navigation and panel visibility
 * 
 * Targets:
 *   - tab: Tab button elements (alias: button)
 *   - panel: Content panel elements
 * 
 * Actions:
 *   - switch: Switches to the clicked tab (alias: select)
 * 
 * Values:
 *   - activeTab: Current active tab ID (optional)
 * 
 * Supports two API modes:
 * 
 * Mode 1 (data-tab-id): Used in show views
 *   <div data-controller="tabs">
 *     <button data-action="click->tabs#switch" 
 *             data-tabs-target="tab" 
 *             data-tab-id="basic"
 *             data-active="true">Tab 1</button>
 *     <div data-tabs-target="panel" data-tab-id="basic">Content 1</div>
 *   </div>
 * 
 * Mode 2 (data-tab): Used in form views
 *   <div data-controller="tabs" data-tabs-active-tab-value="basic">
 *     <button data-action="click->tabs#select" 
 *             data-tabs-target="button" 
 *             data-tab="basic">Tab 1</button>
 *     <div data-tabs-target="panel" data-tab="basic">Content 1</div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["tab", "button", "panel"]
  static values = {
    activeTab: String
  }

  declare readonly tabTargets: HTMLElement[]
  declare readonly buttonTargets: HTMLElement[]
  declare readonly panelTargets: HTMLElement[]
  declare readonly hasTabTarget: boolean
  declare readonly hasButtonTarget: boolean
  declare activeTabValue?: string

  connect() {
    // Determine which targets are available
    const tabs = this.hasButtonTarget ? this.buttonTargets : this.tabTargets
    
    // Initialize: Show the active tab on page load
    let initialTabId: string | null = null
    
    // Priority 1: activeTab value
    if (this.activeTabValue) {
      initialTabId = this.activeTabValue
    } else {
      // Priority 2: data-active="true" attribute
      const activeTab = tabs.find(tab => 
        tab.getAttribute("data-active") === "true"
      )
      
      if (activeTab) {
        initialTabId = this.getTabId(activeTab)
      } else if (tabs.length > 0) {
        // Priority 3: First tab
        initialTabId = this.getTabId(tabs[0])
      }
    }
    
    if (initialTabId) {
      this.showTab(initialTabId)
    }
  }

  // Main method: switch (alias for select)
  switch(event: Event) {
    const target = event.currentTarget as HTMLElement
    const tabId = this.getTabId(target)
    
    if (tabId) {
      this.showTab(tabId)
    }
  }

  // Alias method for compatibility
  select(event: Event) {
    this.switch(event)
  }

  private getTabId(element: HTMLElement): string | null {
    // Try data-tab-id first (Mode 1)
    let tabId = element.getAttribute("data-tab-id")
    
    // Fallback to data-tab (Mode 2)
    if (!tabId) {
      tabId = element.getAttribute("data-tab")
    }
    
    return tabId
  }

  private showTab(tabId: string) {
    const tabs = this.hasButtonTarget ? this.buttonTargets : this.tabTargets
    
    // Update tab button states
    tabs.forEach(tab => {
      const currentTabId = this.getTabId(tab)
      const isActive = currentTabId === tabId
      
      if (isActive) {
        // Set data-active attribute
        tab.setAttribute("data-active", "true")
        
        // Add active classes
        tab.classList.add("active")
        
        // Update border and text colors (for form tabs)
        if (tab.classList.contains("tab-button")) {
          tab.classList.remove("border-transparent", "text-secondary")
          tab.classList.add("border-primary", "text-primary")
          // Add font-semibold for active state
          tab.classList.add("font-semibold")
        }
      } else {
        // Remove data-active attribute
        tab.removeAttribute("data-active")
        
        // Remove active classes
        tab.classList.remove("active")
        
        // Update border and text colors (for form tabs)
        if (tab.classList.contains("tab-button")) {
          tab.classList.remove("border-primary", "text-primary", "font-semibold")
          tab.classList.add("border-transparent", "text-secondary")
        }
      }
    })

    // Update panel visibility
    this.panelTargets.forEach(panel => {
      const currentPanelId = this.getTabId(panel)
      const isActive = currentPanelId === tabId
      
      if (isActive) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
