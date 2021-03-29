//
//  StockCardVC.swift
//  Financer
//
//  Created by Никита Раташнюк on 24.03.2021.
//

import UIKit
import Charts
import TinyConstraints

class StockCardVC: UIViewController, ChartViewDelegate {
    
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var shiftLabel: UILabel!
    @IBOutlet var chartView: UIView!
    @IBOutlet var periodSelector: UIStackView!
    @IBOutlet var chartLabel: UILabel!
    
    lazy var lineChartView: LineChartView = {
        let chartView = LineChartView()
        chartView.rightAxis.enabled = false
        chartView.leftAxis.enabled = false
        chartView.xAxis.enabled = false
        chartView.legend.enabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        
        chartView.noDataText = "Loading..."
        chartView.noDataFont = UIFont(name: "Montserrat SemiBold", size: 20.0)!
        
        chartView.drawMarkers = true
        
        return chartView
    }()
    var stock: Stock!
    var tickerLabel: UILabel!
    var nameLabel: UILabel!
    var delegate: FavouriteDelegate?
    var marker = ChartMarker()
    private var workItem: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .white
        self.navigationController?.navigationBar.standardAppearance = appearance
        
        priceLabel.text = stock.formatCurrentPrice()
        shiftLabel.text = stock.formatShift()
        chartLabel.layer.cornerRadius = 10
        chartLabel.layer.masksToBounds = true

        chartView.addSubview(lineChartView)
        lineChartView.centerInSuperview()
        lineChartView.width(to: chartView)
        lineChartView.height(to: chartView)
        
        marker.chartView = lineChartView
        lineChartView.marker = marker
        
        setupNavBar()
        
        for subview in periodSelector.subviews {
            if subview.isKind(of: UIButton.self) {
                subview.backgroundColor = UIColor(hex: "#F0F4F7")
                subview.layer.cornerRadius = 20
                let button = subview as! UIButton
                button.addTarget(self, action: #selector(periodSelected), for: .touchUpInside)
                if button.currentTitle == "M" {
                    periodSelected(button: button)
                }
            }
        }
        
        lineChartView.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        tickerLabel.constraints.forEach { $0.isActive = false }
        tickerLabel.removeFromSuperview()
        nameLabel.constraints.forEach { $0.isActive = false }
        nameLabel.removeFromSuperview()
    }
    
    private func setupNavBar() {
        if let navigationBar = self.navigationController?.navigationBar {
            var font = UIFont(name: "Montserrat Bold", size: 20.0)
            var fontAttributes = [NSAttributedString.Key.font: font]
            var size = stock.ticker.size(withAttributes: fontAttributes as [NSAttributedString.Key : Any])
            let firstFrame = CGRect(x: navigationBar.frame.width / 2 - size.width / 2, y: 0, width: 0, height: 0)
            
            tickerLabel = UILabel(frame: firstFrame)
            tickerLabel.font = font
            tickerLabel.text = stock.ticker
            tickerLabel.textColor = .black
            tickerLabel.sizeToFit()
            
            font = UIFont(name: "Montserrat Medium", size: 14.0)
            fontAttributes = [NSAttributedString.Key.font: font]
            size = stock.companyName.size(withAttributes: fontAttributes as [NSAttributedString.Key : Any])
            let secondFrame = CGRect(x: navigationBar.frame.width / 2 - size.width / 2, y: tickerLabel.frame.height + 1, width: 0, height: 0)
            
            nameLabel = UILabel(frame: secondFrame)
            nameLabel.font = font
            nameLabel.text = stock.companyName
            nameLabel.textColor = .black
            nameLabel.sizeToFit()

            navigationBar.addSubview(tickerLabel)
            navigationBar.addSubview(nameLabel)
        }
        
        var image = UIImage(named: "star")
        if isFavourite(ticker: stock.ticker) { image = UIImage(named: "yellow_star") }
        navigationItem.loadRightImage(image: image, target: self, selector: #selector(modifyFav))
        
        image = UIImage(named: "arrow_back")
        navigationItem.loadLeftImage(image: image, target: self, selector: #selector(popToPrevious))
    }
    
    @objc private func popToPrevious() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func modifyFav() {
        delegate?.modifyFavourites(stock: stock)
        
        var imgName = "star"
        if isFavourite(ticker: stock.ticker) { imgName = "yellow_star" }
        navigationItem.loadRightImage(image: UIImage(named: imgName), target: self, selector: #selector(modifyFav))
    }
    
    @objc func periodSelected(button: UIButton) {
        resetStackStyle()
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        
        loadGraph(resolution: button.currentTitle!)
    }
    
    func resetStackStyle() {
        for subview in periodSelector.subviews {
            if subview.isKind(of: UIButton.self) {
                let button = subview as! UIButton
                button.backgroundColor = UIColor(hex: "#F0F4F7")
                button.setTitleColor(.black, for: .normal)
            }
        }
    }
    
    func loadGraph(resolution: String) {
        lineChartView.noDataText = "Loading..."
        lineChartView.data = nil
        if (workItem != nil) { workItem!.cancel() }
        
        workItem = DispatchWorkItem {
            var values = [ChartDataEntry]()
            if let candle = loadCandle(for: self.stock, resolution: resolution) {
                for i in 0..<candle.closePrices.count {
                    values.append(ChartDataEntry(x: Double(i), y: candle.closePrices[i]))
                }
                self.marker.dates = candle.getFormattedDates()
            }
            DispatchQueue.main.async {
                if values.count == 0 {
                    self.lineChartView.noDataText = "No Data"
                    self.lineChartView.data = nil
                } else {
                    self.setLineChartData(yValues: values)
                    self.lineChartView.animate(xAxisDuration: 2.0, easingOption: .easeOutSine)
                }
            }
        }
        DispatchQueue.global(qos: .utility).async(execute: workItem!)
    }
    
    func setLineChartData(yValues: [ChartDataEntry]) {
        let dataset = LineChartDataSet(entries: yValues)
        dataset.mode = .cubicBezier
        dataset.lineWidth = 4
        dataset.setColor(.black)
        dataset.drawCirclesEnabled = false
        dataset.drawValuesEnabled = false
        dataset.drawHorizontalHighlightIndicatorEnabled = false
        dataset.highlightColor = .black
        
        let gradientColors = [UIColor.black.cgColor, UIColor.clear.cgColor] as CFArray
        let colorLocations:[CGFloat] = [1.0, 0.0]
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations)
        dataset.fill = Fill(linearGradient: gradient!, angle: 90.0)
        dataset.drawFilledEnabled = true
        
        let data = LineChartData(dataSet: dataset)
        lineChartView.data = data
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // print(entry)
    }
    
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        chartView.highlightValue(nil)
    }

}
