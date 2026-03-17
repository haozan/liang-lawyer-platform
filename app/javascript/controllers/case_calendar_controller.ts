import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = [
    "yearInput",
    "monthInput",
    "modal",
    "modalTitle",
    "modalContent"
  ]

  declare readonly yearInputTarget: HTMLInputElement
  declare readonly monthInputTarget: HTMLInputElement
  declare readonly modalTarget: HTMLElement
  declare readonly modalTitleTarget: HTMLElement
  declare readonly modalContentTarget: HTMLElement

  previousMonth(): void {
    const currentYear = parseInt(this.yearInputTarget.value)
    const currentMonth = parseInt(this.monthInputTarget.value)
    
    let newYear = currentYear
    let newMonth = currentMonth - 1
    
    if (newMonth < 1) {
      newMonth = 12
      newYear -= 1
    }
    
    this.navigateToMonth(newYear, newMonth)
  }

  nextMonth(): void {
    const currentYear = parseInt(this.yearInputTarget.value)
    const currentMonth = parseInt(this.monthInputTarget.value)
    
    let newYear = currentYear
    let newMonth = currentMonth + 1
    
    if (newMonth > 12) {
      newMonth = 1
      newYear += 1
    }
    
    this.navigateToMonth(newYear, newMonth)
  }

  private navigateToMonth(year: number, month: number): void {
    const form = this.element.querySelector('form')
    if (!form) return
    
    this.yearInputTarget.value = year.toString()
    this.monthInputTarget.value = month.toString()
    
    form.requestSubmit()  // Turbo handles automatically
  }

  showDayEvents(event: Event): void {
    const button = event.currentTarget as HTMLButtonElement
    const date = button.dataset.date
    const eventsJson = button.dataset.events
    
    if (!date || !eventsJson) return
    
    try {
      const events = JSON.parse(eventsJson)
      
      const dateObj = new Date(date)
      const formattedDate = dateObj.toLocaleDateString('zh-CN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        weekday: 'long'
      })
      this.modalTitleTarget.textContent = formattedDate
      
      const eventHtml = events.map((evt: any) => {
        const colorClasses = this.getColorClasses(evt.color)
        return `
          <a href="/cases/${evt.case.id}" 
             class="block p-4 rounded-lg ${colorClasses.bg} hover:shadow-md transition-shadow">
            <div class="flex items-start gap-3">
              <div class="${colorClasses.icon}">
                ${this.getIconSvg(evt.icon)}
              </div>
              <div class="flex-1 min-w-0">
                <span class="badge ${colorClasses.badge}">${evt.type}</span>
                <h4 class="font-semibold text-primary mt-1">${evt.case.name}</h4>
                <p class="text-sm text-secondary mt-1">
                  案号：${evt.case.case_number || '待立案'}
                </p>
              </div>
            </div>
          </a>
        `
      }).join('')
      
      this.modalContentTarget.innerHTML = eventHtml
      this.modalTarget.classList.remove('hidden')
      document.body.style.overflow = 'hidden'
      
    } catch (error) {
      console.error('Failed to parse events:', error)
    }
  }

  closeModal(): void {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = ''
  }
  
  private getColorClasses(color: string) {
    const colorMap: Record<string, { bg: string; icon: string; badge: string }> = {
      info: {
        bg: 'bg-info-50 dark:bg-info-900/20',
        icon: 'text-info-600',
        badge: 'badge-info'
      },
      success: {
        bg: 'bg-success-50 dark:bg-success-900/20',
        icon: 'text-success-600',
        badge: 'badge-success'
      },
      warning: {
        bg: 'bg-warning-50 dark:bg-warning-900/20',
        icon: 'text-warning-600',
        badge: 'badge-warning'
      },
      danger: {
        bg: 'bg-danger-50 dark:bg-danger-900/20',
        icon: 'text-danger-600',
        badge: 'badge-danger'
      },
      neutral: {
        bg: 'bg-neutral-50 dark:bg-neutral-800',
        icon: 'text-neutral-600',
        badge: 'badge-neutral'
      }
    }
    
    return colorMap[color] || colorMap.info
  }
  
  private getIconSvg(iconName: string): string {
    const iconMap: Record<string, string> = {
      'file-text': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><line x1="10" y1="9" x2="8" y2="9"/></svg>',
      'gavel': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m14 13-7.5 7.5c-.83.83-2.17.83-3 0 0 0 0 0 0 0a2.12 2.12 0 0 1 0-3L11 10"/><path d="m16 16 6-6"/><path d="m8 8 6-6"/><path d="m9 7 8 8"/><path d="m21 11-8-8"/></svg>',
      'file-check': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/><polyline points="9 15 11 17 15 13"/></svg>',
      'archive': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="5" rx="1"/><path d="M4 8v11a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8"/><path d="M10 12h4"/></svg>',
      'shield-alert': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="M12 8v4"/><path d="M12 16h.01"/></svg>',
      'clock': '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>'
    }
    
    return iconMap[iconName] || iconMap['file-text']
  }
}
