import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["userTab", "lawyerTab", "userForm", "lawyerForm"]

  declare readonly userTabTarget: HTMLButtonElement
  declare readonly lawyerTabTarget: HTMLButtonElement
  declare readonly userFormTarget: HTMLElement
  declare readonly lawyerFormTarget: HTMLElement

  connect(): void {
    this.showUser()
  }

  showUser(): void {
    this.userTabTarget.classList.add("bg-primary", "text-surface", "shadow-sm")
    this.userTabTarget.classList.remove("text-secondary")
    this.lawyerTabTarget.classList.remove("bg-primary", "text-surface", "shadow-sm")
    this.lawyerTabTarget.classList.add("text-secondary")

    this.userFormTarget.style.display = "block"
    this.lawyerFormTarget.style.display = "none"
  }

  showLawyer(): void {
    this.lawyerTabTarget.classList.add("bg-primary", "text-surface", "shadow-sm")
    this.lawyerTabTarget.classList.remove("text-secondary")
    this.userTabTarget.classList.remove("bg-primary", "text-surface", "shadow-sm")
    this.userTabTarget.classList.add("text-secondary")

    this.lawyerFormTarget.style.display = "block"
    this.userFormTarget.style.display = "none"
  }
}
