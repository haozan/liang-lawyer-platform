import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["passwordTab", "smsTab", "passwordForm", "smsForm"]

  declare readonly passwordTabTarget: HTMLButtonElement
  declare readonly smsTabTarget: HTMLButtonElement
  declare readonly passwordFormTarget: HTMLElement
  declare readonly smsFormTarget: HTMLElement

  connect(): void {
    console.log("LoginTab connected")
  }

  showPassword(): void {
    // Update tab styles
    this.passwordTabTarget.classList.add("text-primary", "border-primary")
    this.passwordTabTarget.classList.remove("text-secondary", "border-transparent")
    this.smsTabTarget.classList.add("text-secondary", "border-transparent")
    this.smsTabTarget.classList.remove("text-primary", "border-primary")

    // Show password form, hide SMS form
    this.passwordFormTarget.style.display = "block"
    this.smsFormTarget.style.display = "none"
  }

  showSms(): void {
    // Update tab styles
    this.smsTabTarget.classList.add("text-primary", "border-primary")
    this.smsTabTarget.classList.remove("text-secondary", "border-transparent")
    this.passwordTabTarget.classList.add("text-secondary", "border-transparent")
    this.passwordTabTarget.classList.remove("text-primary", "border-primary")

    // Show SMS form, hide password form
    this.smsFormTarget.style.display = "block"
    this.passwordFormTarget.style.display = "none"
  }
}
