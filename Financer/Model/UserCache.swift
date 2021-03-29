//
//  UserCache.swift
//  Financer
//
//  Created by Никита Раташнюк on 12.03.2021.
//

import Foundation
import UIKit

let imageCache = NSCache<NSString, UIImage>()
let storage = UserDefaults.standard

func downloadImage(url: URL, completion: @escaping (UIImage?) -> Void) {
    // DispatchQueue.global().async {
        if let cachedImageData = storage.object(forKey: url.absoluteString) {
            let image = UIImage(data: cachedImageData as! Data)
            print("I took it from cache")
            completion(image)
        } else {
            guard let imageData = try? Data(contentsOf: url) else { completion(nil); return }
            print("I downloaded it")
            
            guard let image = UIImage(data: imageData) else {
                completion(nil)
                return
            }
            
            storage.setValue(imageData, forKey: url.absoluteString)
            completion(image)
//        }
    }
}

func addToHistory(s: String) {
    if var historyTickers = storage.object(forKey: "historyTickers") as? [String] {
        if historyTickers.contains(s) {
            historyTickers.remove(at: historyTickers.firstIndex(of: s)!)
        }
        historyTickers.insert(s, at: 0)
        if historyTickers.count > 10 { historyTickers = Array(historyTickers[0..<10]) }
        storage.setValue(historyTickers, forKey: "historyTickers")
    } else {
        storage.setValue([s], forKey: "historyTickers")
    }
}

func getAllHistoryTickers() -> [String] {
    if let historyTickers = storage.object(forKey: "historyTickers") as? [String] {
        return historyTickers
    }
    return []
}
