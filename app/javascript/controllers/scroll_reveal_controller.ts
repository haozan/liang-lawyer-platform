import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["navbar", "feature", "testimonial", "cta"]

  declare readonly hasNavbarTarget: boolean
  declare readonly navbarTarget: HTMLElement
  declare readonly featureTargets: HTMLElement[]
  declare readonly testimonialTargets: HTMLElement[]
  declare readonly ctaTarget: HTMLElement

  private observer!: IntersectionObserver
  private scrollY: number = 0
  private lastScrollY: number = 0

  connect(): void {
    // Set up Intersection Observer for scroll reveal animations
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('animate-in')
          }
        })
      },
      {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
      }
    )

    // Observe all animated elements
    this.featureTargets.forEach(el => this.observer.observe(el))
    this.testimonialTargets.forEach(el => this.observer.observe(el))

    // Add scroll listener for navbar and CTA
    window.addEventListener('scroll', this.handleScroll.bind(this))
    this.handleScroll()
  }

  disconnect(): void {
    this.observer.disconnect()
    window.removeEventListener('scroll', this.handleScroll.bind(this))
  }

  private handleScroll(): void {
    this.scrollY = window.scrollY
    
    // Navbar hide/show on scroll
    if (this.hasNavbarTarget) {
      if (this.scrollY > this.lastScrollY && this.scrollY > 100) {
        // Scrolling down - hide navbar
        this.navbarTarget.style.transform = 'translateY(-100%)'
      } else {
        // Scrolling up - show navbar
        this.navbarTarget.style.transform = 'translateY(0)'
      }
    }

    // CTA expansion based on scroll progress
    if (this.hasCtaTarget) {
      const scrollHeight = document.documentElement.scrollHeight - window.innerHeight
      const scrollProgress = Math.min(this.scrollY / scrollHeight, 1)
      const expansionWidth = 20 + (scrollProgress * 80) // 20% to 100%
      this.ctaTarget.style.width = `${expansionWidth}%`
    }

    this.lastScrollY = this.scrollY
  }

  private get hasCtaTarget(): boolean {
    try {
      return !!this.ctaTarget
    } catch {
      return false
    }
  }
}
