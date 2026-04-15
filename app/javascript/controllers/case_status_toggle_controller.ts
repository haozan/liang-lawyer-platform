import { Controller } from "@hotwired/stimulus"

/**
 * Case Status Toggle Controller
 * 
 * Handles showing/hiding execution section when case status changes to "execution"
 * 
 * Targets:
 * - statusSelect: The case status dropdown
 * - executionSection: The execution management section
 * 
 * Usage:
 * <div data-controller="case-status-toggle">
 *   <select data-case-status-toggle-target="statusSelect" 
 *           data-action="change->case-status-toggle#toggleExecutionSection">
 *     ...
 *   </select>
 *   <div data-case-status-toggle-target="executionSection">...</div>
 * </div>
 */
export default class extends Controller<HTMLElement> {
  static targets = ["statusSelect", "executionSection"]

  declare readonly statusSelectTarget: HTMLSelectElement
  declare readonly executionSectionTarget: HTMLElement
  declare readonly hasExecutionSectionTarget: boolean

  connect(): void {
    // Initialize visibility on page load
    this.toggleExecutionSection()
  }

  toggleExecutionSection(): void {
    if (!this.hasExecutionSectionTarget) return

    const status = this.statusSelectTarget.value

    if (status === "execution") {
      this.executionSectionTarget.style.display = ""
    } else {
      this.executionSectionTarget.style.display = "none"
    }
  }
}
