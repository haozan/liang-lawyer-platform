import { Controller } from "@hotwired/stimulus"

/**
 * Pending Tasks Controller
 * 
 * Handles clicks on pending task items and switches to the corresponding tab
 * 
 * Targets: none
 * 
 * Actions:
 *   - switchTab: Switches to the tab specified in data-tab attribute
 * 
 * Usage:
 *   <div data-controller="pending-tasks">
 *     <button data-action="click->pending-tasks#switchTab" 
 *             data-tab="work-logs">
 *       View work logs
 *     </button>
 *   </div>
 */
export default class extends Controller {
  switchTab(event: Event) {
    const button = event.currentTarget as HTMLElement
    const tabId = button.getAttribute("data-tab")
    
    if (!tabId) {
      console.warn("No data-tab attribute found on pending task button")
      return
    }
    
    // Find the tabs controller element
    const tabsController = document.querySelector('[data-controller*="tabs"]')
    
    if (!tabsController) {
      console.warn("No tabs controller found on page")
      return
    }
    
    // Find the target tab button within the tabs controller
    const targetTabButton = tabsController.querySelector(
      `[data-tab="${tabId}"], [data-tab-id="${tabId}"]`
    ) as HTMLElement
    
    if (!targetTabButton) {
      console.warn(`No tab button found for tab ID: ${tabId}`)
      return
    }
    
    // Trigger click on the target tab button
    targetTabButton.click()
    
    // Scroll to the tabs section smoothly
    tabsController.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}
