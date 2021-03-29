//
//  ChartMarker.swift
//  Financer
//
//  Created by Никита Раташнюк on 27.03.2021.
//

import UIKit
import Charts

class ChartMarker: MarkerView {
    var dates: [String]!
    var label1: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont(name: "Montserrat Bold", size: 20.0)!
        return label
    }()
    var label2: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = UIFont(name: "Montserrat Bold", size: 15.0)!
        return label
    }()

    private let drawAttributes1: [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "Montserrat Bold", size: 20.0)!,
        .foregroundColor: UIColor.white,
        .backgroundColor: UIColor.black
    ]
    private let drawAttributes2: [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "Montserrat Bold", size: 15.0)!,
        .foregroundColor: UIColor.gray,
        .backgroundColor: UIColor.black
    ]

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        
        label1.text = "$" + String(format: "%.02f", (entry.y))
        label2.text = dates[Int(entry.x)]
        let size1 = label1.text!.size(withAttributes: drawAttributes1)
        let size2 = label2.text!.size(withAttributes: drawAttributes2)
        label1.sizeToFit()
        label2.sizeToFit()
        
        self.backgroundColor = .black
        self.layer.cornerRadius = 10
        self.frame.size = CGSize(width: max(size1.width, size2.width) + 10, height: size1.height + size2.height + 5)
        
        self.addSubview(label1)
        self.addSubview(label2)
        
        label1.center.x = self.center.x
        label2.center.x = self.center.x
        label2.center.y = label1.center.y + label1.frame.height - 5
    }

    override func draw(context: CGContext, point: CGPoint) {
        offset = CGPoint(x: -self.frame.width / 4, y: -self.frame.height)

        let offset = offsetForDrawing(atPoint: point)
        let originPoint = CGPoint(x: point.x + offset.x, y: point.y + offset.y)
        
        super.draw(context: context, point: originPoint)
    }
}
