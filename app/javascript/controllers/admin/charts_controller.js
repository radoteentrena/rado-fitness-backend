import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

export default class extends Controller {
  static targets = ["chart"]

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
      tooltip: {
        enabled: true,
        x: {
          show: false,
        },
      },
      fill: {
        type: "gradient",
        gradient: {
          opacityFrom: 0.55,
          opacityTo: 0,
          shade: "#1C64F2",
          gradientToColors: ["#1C64F2"],
        },
      },
      dataLabels: {
        enabled: false,
      },
      stroke: {
        width: 6,
      },
      grid: {
        show: false,
        strokeDashArray: 4,
        padding: {
          left: 2,
          right: 2,
          top: 0
        },
      },
      series: [
        {
          name: "New users",
          data: [6500, 6418, 6456, 6526, 6356, 6456],
          color: "#1A56DB",
        },
      ],
      xaxis: {
        categories: ['01 Feb', '02 Feb', '03 Feb', '04 Feb', '05 Feb', '06 Feb', '07 Feb'],
        labels: {
          show: false,
        },
        axisBorder: {
          show: false,
        },
        axisTicks: {
          show: false,
        },
      },
      yaxis: {
        show: false,
      },
    }
  }
}
