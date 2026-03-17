import { Controller } from "@hotwired/stimulus"
import * as echarts from "echarts"

// Dashboard Chart Controller - 仪表盘专业图表组件
// 支持: 速度表盘(gauge)、雷达图(radar)、瀑布图(waterfall)、环形图(donut)
export default class extends Controller<HTMLElement> {
  static targets = ["chart"]
  static values = {
    type: String,      // 图表类型: gauge, radar, waterfall, donut
    data: Object,      // 图表数据
    options: Object    // 自定义配置
  }
  
  declare readonly chartTarget: HTMLElement
  declare readonly typeValue: string
  declare readonly dataValue: any
  declare readonly optionsValue: any
  
  private chartInstance: echarts.ECharts | null = null
  
  connect(): void {
    this.initChart()
    
    // 响应式处理
    window.addEventListener('resize', this.handleResize.bind(this))
  }
  
  disconnect(): void {
    if (this.chartInstance) {
      this.chartInstance.dispose()
    }
    window.removeEventListener('resize', this.handleResize.bind(this))
  }
  
  private initChart(): void {
    if (!this.chartTarget) return
    
    this.chartInstance = echarts.init(this.chartTarget)
    
    let option: any
    
    switch (this.typeValue) {
      case 'gauge':
        option = this.getGaugeOption()
        break
      case 'radar':
        option = this.getRadarOption()
        break
      case 'waterfall':
        option = this.getWaterfallOption()
        break
      case 'donut':
        option = this.getDonutOption()
        break
      case 'bar':
        option = this.getBarOption()
        break
      case 'line':
        option = this.getLineOption()
        break
      default:
        option = this.getDefaultOption()
    }
    
    // 合并自定义配置
    if (this.optionsValue) {
      option = { ...option, ...this.optionsValue }
    }
    
    this.chartInstance.setOption(option)
  }
  
  private getGaugeOption(): any {
    const value = this.dataValue.value || 0
    const max = this.dataValue.max || 100
    const name = this.dataValue.name || '完成率'
    
    return {
      series: [
        {
          type: 'gauge',
          startAngle: 180,
          endAngle: 0,
          min: 0,
          max: max,
          splitNumber: 5,
          axisLine: {
            lineStyle: {
              width: 16,
              color: [
                [0.3, '#ff6b6b'],
                [0.7, '#feca57'],
                [1, '#48dbfb']
              ]
            }
          },
          pointer: {
            itemStyle: {
              color: 'auto'
            }
          },
          axisTick: {
            distance: -16,
            length: 5,
            lineStyle: {
              color: '#fff',
              width: 1
            }
          },
          splitLine: {
            distance: -20,
            length: 10,
            lineStyle: {
              color: '#fff',
              width: 2
            }
          },
          axisLabel: {
            distance: 10,
            color: '#999',
            fontSize: 12
          },
          detail: {
            valueAnimation: true,
            formatter: '{value}%',
            color: 'inherit',
            fontSize: 24,
            offsetCenter: [0, '80%']
          },
          title: {
            offsetCenter: [0, '100%'],
            fontSize: 14,
            color: '#666'
          },
          data: [
            {
              value: value,
              name: name
            }
          ]
        }
      ]
    }
  }
  
  private getRadarOption(): any {
    const indicator = this.dataValue.indicator || []
    const data = this.dataValue.data || []
    
    return {
      tooltip: {
        trigger: 'item'
      },
      radar: {
        indicator: indicator,
        shape: 'polygon',
        splitNumber: 4,
        axisName: {
          color: '#666',
          fontSize: 12
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(0, 0, 0, 0.1)'
          }
        },
        splitArea: {
          show: true,
          areaStyle: {
            color: ['rgba(114, 172, 209, 0.05)', 'rgba(114, 172, 209, 0.1)']
          }
        },
        axisLine: {
          lineStyle: {
            color: 'rgba(0, 0, 0, 0.1)'
          }
        }
      },
      series: [
        {
          type: 'radar',
          data: data,
          areaStyle: {
            opacity: 0.3
          },
          lineStyle: {
            width: 2
          },
          itemStyle: {
            color: '#5470c6'
          }
        }
      ]
    }
  }
  
  private getWaterfallOption(): any {
    const categories = this.dataValue.categories || []
    const data = this.dataValue.data || []
    
    return {
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow'
        }
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        data: categories,
        axisLabel: {
          rotate: 30,
          fontSize: 11
        }
      },
      yAxis: {
        type: 'value'
      },
      series: [
        {
          type: 'bar',
          data: data,
          itemStyle: {
            color: (params: any) => {
              return params.value > 0 ? '#52c41a' : '#ff4d4f'
            }
          },
          label: {
            show: true,
            position: 'top',
            formatter: (params: any) => {
              return params.value > 0 ? `+${params.value}` : params.value
            }
          }
        }
      ]
    }
  }
  
  private getDonutOption(): any {
    const data = this.dataValue.data || []
    const name = this.dataValue.name || ''
    
    return {
      tooltip: {
        trigger: 'item',
        formatter: '{b}: {c} ({d}%)'
      },
      legend: {
        orient: 'vertical',
        right: 10,
        top: 'center',
        textStyle: {
          fontSize: 12
        }
      },
      series: [
        {
          name: name,
          type: 'pie',
          radius: ['50%', '70%'],
          avoidLabelOverlap: false,
          itemStyle: {
            borderRadius: 10,
            borderColor: '#fff',
            borderWidth: 2
          },
          label: {
            show: false,
            position: 'center'
          },
          emphasis: {
            label: {
              show: true,
              fontSize: 20,
              fontWeight: 'bold'
            }
          },
          labelLine: {
            show: false
          },
          data: data
        }
      ]
    }
  }
  
  private getBarOption(): any {
    const categories = this.dataValue.categories || []
    const series = this.dataValue.series || []
    
    return {
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow'
        }
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        data: categories,
        axisLabel: {
          fontSize: 11,
          interval: 0,
          rotate: categories.length > 10 ? 30 : 0
        }
      },
      yAxis: {
        type: 'value'
      },
      series: series
    }
  }
  
  private getLineOption(): any {
    const categories = this.dataValue.categories || []
    const series = this.dataValue.series || []
    
    return {
      tooltip: {
        trigger: 'axis'
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        data: categories,
        boundaryGap: false
      },
      yAxis: {
        type: 'value'
      },
      series: series
    }
  }
  
  private getDefaultOption(): any {
    return {}
  }
  
  private handleResize(): void {
    if (this.chartInstance) {
      this.chartInstance.resize()
    }
  }
  
  // 公共方法：更新图表数据
  updateData(newData: any): void {
    // 使用setAttribute更新data-value属性，不直接赋值给dataValue
    this.element.setAttribute('data-dashboard-chart-data-value', JSON.stringify(newData))
    this.initChart()
  }
}
