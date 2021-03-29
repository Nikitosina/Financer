//
//  Extensions.swift
//  Financer
//
//  Created by Никита Раташнюк on 12.03.2021.
//

import Foundation
import UIKit

extension UIImageView {
    func setImage(from url: URL) {
        DispatchQueue.global().async {
            guard let imageData = try? Data(contentsOf: url) else { return }

            let image = UIImage(data: imageData, scale: 1.0)
            
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    self.init(
                            red: CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0,
                            green: CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0,
                            blue: CGFloat(hexNumber & 0x0000FF) / 255.0,
                            alpha: CGFloat(1.0)
                        )
                    return
                }
            }
        }

        return nil
    }
}

extension UISearchBar {
    func setLeftImage(_ image: UIImage) {
        let imageView = UIImageView()
        imageView.image = image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        searchTextField.leftView = imageView
    }
}

extension UITableView {
    func showMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "Montserrat Bold", size: 20.0)
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
    }
    
    func showActivityIndicator() {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.center
        activityIndicator.style = .large
        activityIndicator.startAnimating()
        self.backgroundView = activityIndicator
    }
    
    func eraseBG() {
        self.backgroundView = nil
    }
}

extension UINavigationItem {
    func loadRightImage(image: UIImage?, target: Any?, selector: Selector?) {
        let backButton = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 30, height: 30))
        backButton.setImage(image, for: .normal)
        backButton.addTarget(target, action: selector!, for: .touchUpInside)
        self.rightBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    func loadLeftImage(image: UIImage?, target: Any?, selector: Selector?) {
        let img = image?.withRenderingMode(.alwaysOriginal)
        self.leftBarButtonItem = UIBarButtonItem(
            image: img,
            style: .plain,
            target: target,
            action: selector
        )
    }
}

//extension UICollectionViewCell {
//    func styleItem(text: String) {
//        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
//        label.text = text
//        label.textAlignment = .center
//        label.font = UIFont(name: "Montserrat Bold", size: 10.0)
//        label.sizeToFit()
//        self.layer.cornerRadius = 10
//        self.backgroundColor = UIColor(hex: "#F0F4F7")
//        self.addSubview(label)
//    }
//}
