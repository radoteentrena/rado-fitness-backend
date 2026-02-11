import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

export default class extends Controller {
  static targets = ["chart"]
  static values = {
    series: Array,
    categories: Array
  }

  connect() {
    this.renderChart()
  }

  renderChart() {
    const options = this.getOptions()
    const chart = new ApexCharts(this.chartTarget, options)
    chart.render()
  }

  getOptions() {
    return {
      chart: {
        height: "100%",
        maxWidth: "100%",
        type: "area",
        fontFamily: "Inter, sans-serif",
        dropShadow: {
          enabled: false,
        },
        toolbar: {
          show: false,
        },
      },
      colors: ['#F5C228'], // Primary color for the line
      tooltip: {
        enabled: true,
        x: {
          show: true,
        },
      },
      fill: {
        type: "gradient",
        gradient: {
          opacityFrom: 0.55,
          opacityTo: 0,
          shade: "#F5C228",
          gradientToColors: ["#F5C228"],
        },
      },
      dataLabels: {
        enabled: true,
        style: {
          colors: ['#F5C228']
        }
      },
      stroke: {
        width: 6,
      },
      grid: {
        show: true, // Show grid for better readability
        strokeDashArray: 4,
        padding: {
          left: 10,
          right: 10,
          top: 0
        },
      },
      series: this.seriesValue || [],
      xaxis: {
        categories: this.categoriesValue || [],
        labels: {
          show: true, // Show X-axis labels (Dates)
          style: {
            fontFamily: "Inter, sans-serif",
            cssClass: 'text-xs fill-gray-500 dark:fill-gray-400'
          }
        },
        axisBorder: {
          show: false,
        },
        axisTicks: {
          show: false,
        },
      },
      yaxis: {
        show: true, // Show Y-axis labels (Counts)
        labels: {
           formatter: function (val) {
             return val.toFixed(0); // Integers only for user counts
           }
        }
      },
    }
  }
}
