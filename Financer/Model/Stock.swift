//
//  Stock.swift
//  Financer
//
//  Created by Никита Раташнюк on 04.03.2021.
//

import Foundation
import UIKit

let FINNHUB_APIKEY = "c10bkof48v6q5hkb9hh0"
let MBOUM_APIKEY = "w5uIYTTLLVmWnGMX5cUY4k3PNwqQ9IOAPo6lav5Xyw9IBj4SqMCJmyxQUz6u"
var favStockList = [Stock]()

struct Quote {
    let currentPrice: Double
    let highestPriceOfDay: Double
    let lowestPriceOfDay: Double
    let openPriceOfDay: Double
    let previousClosePrice: Double
}

struct Stock {
    let companyName: String
    let ticker: String
    let quote: Quote
    let currency: String
    let country: String
    let industry: String
    let icon: UIImage!
    
    func formatCurrentPrice() -> String {
        return "$" + String(format: "%.02f", (self.quote.currentPrice))
    }
    
    func shiftColor() -> UIColor {
        let shift = self.quote.currentPrice - self.quote.previousClosePrice
        if shift < 0 { return .systemRed }
        else if shift == 0 { return .systemGray }
        return .systemGreen
    }
    
    func formatShift() -> String {
        var shift = self.quote.currentPrice - self.quote.previousClosePrice
        let shiftPercentage = abs((1 - (self.quote.currentPrice / self.quote.previousClosePrice)) * 100)
        var symbol = "+"
        
        if shift < 0 {
            shift = abs(shift)
            symbol = "-"
        }
        else if shift == 0 {
            symbol = ""
        }
        
        let res = symbol + "$" + String(format: "%.02f", (shift)) + " (" + String(format: "%.02f", locale: Locale(identifier: "ru"), (shiftPercentage)) + "%)"
        
        return res
    }
}

struct TrendingListResponse: Decodable {
    let count: Int
    let quotes: [String]
    let jobTimestamp: Int
    let startInterval: Int
}

func isFavourite(ticker: String) -> Bool {
    if let allFavourites = UserDefaults.standard.object(forKey: "fav") as? [String] {
        if allFavourites.contains(ticker) { return true }
    }
    return false
}

func getAllFavourites() -> [String] {
    if let allFavourites = UserDefaults.standard.object(forKey: "fav") as? [String] {
        return allFavourites
    }
    return []
}

func search(by request: String, task: DispatchWorkItem, completion: @escaping ([Stock]?) -> Void) {
    guard let url = URL(string: "https://finnhub.io/api/v1/search?q=\(request)&token=\(FINNHUB_APIKEY)") else {
        print("URL not found")
        completion(nil)
        return
    }
    do {
        let content = try String(contentsOf: url)
        let data = content.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let resp = json as? [String: Any] else {
            print("Could not parse")
            completion(nil)
            return
        }
        
        var count = resp["count"] as! Int
        let result = resp["result"] as! [[String: Any]]
        var res = [Stock]()
        
        if count == 0 { completion(nil); return }
        if count > 6 { count = 6 }
        
        // let queue = OperationQueue()
        // queue.maxConcurrentOperationCount = 1
        let group = DispatchGroup()
        let dispatchQueue = DispatchQueue.global(qos: .default)
        
        for i in 0..<count {
            if task.isCancelled {
                return
            }
            
            if result[i]["type"] as! String == "Common Stock" {
                let symbol = result[i]["symbol"] as! String
                
                // queue.addOperation {
                group.enter()
                dispatchQueue.async {
                    if let stock = loadStockDataFromURL(ticker: symbol) {
                        res.append(stock)
                    }
                    group.leave()
                }
                // }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("jobs done by group")
            if res.count > 0 { completion(res) }
            else { completion(nil) }
            return
        }
    } catch {
        print(error.localizedDescription)
    }
    
    return
}

// somehow fails to find API
func getTrendingStocks(limit: Int) -> [String] {
    // let symbol = "^GSPC"
    guard let url = URL(string: "https://finnhub.io/api/v1/index/constituents?symbol=^GSPC&token=c10bkof48v6q5hkb9hh0") else {
        print("API Not Found")
        return []
    }
    do {
        let content = try String(contentsOf: url)
        // content = String(content.dropFirst(1).dropLast(1))
        
        print(content)
        
        let data = content.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
//        if let trendingList = try? JSONDecoder().decode(TrendingListResponse.self, from: data) {
//            return Array(trendingList.quotes[0..<limit])
        
        guard let resp = json as? [String: Any] else {
            print("Couldn't parse")
            return []
        }
        
        let tickersList = resp["constituents"] as! [String]
        return Array(tickersList[0..<limit])
        
    } catch {
        print(error.localizedDescription)
    }
    return []
}


func loadStockDataFromURL(ticker: String) -> Stock? {
    guard let urlQuote = URL(string: "https://finnhub.io/api/v1/quote?symbol=\(ticker)&token=\(FINNHUB_APIKEY)") else {
        print("API Not Found (quote)")
        return nil
    }
    
    guard let urlProfile = URL(string: "https://finnhub.io/api/v1/stock/profile2?symbol=\(ticker)&token=\(FINNHUB_APIKEY)") else {
        print("API Not Found (profile)")
        return nil
    }
    
    do {
        // Getting current quote
        var content = try String(contentsOf: urlQuote)
        var data = content.data(using: .utf8)!
        var json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let quoteResp = json as? [String: Double] else {
            print("Couldn't parse quote")
            return nil
        }
        
        let quote = Quote(currentPrice: quoteResp["c"]!, highestPriceOfDay: quoteResp["h"]!, lowestPriceOfDay: quoteResp["l"]!, openPriceOfDay: quoteResp["o"]!, previousClosePrice: quoteResp["pc"]!)
        
        // Getting profile of company
        content = try String(contentsOf: urlProfile)
        // content = String(content.dropFirst(1).dropLast(1))
        
        data = content.data(using: .utf8)!
        json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let profileResp = json as? [String: Any] else {
            print("Couldn't parse profile")
            return nil
        }
        
        // Getting logo image
        // print(profileResp["logo"])
        var icon = UIImage()
        
        if let urlImage = URL(string: "https://finnhub.io/api/logo?symbol=\(ticker)") {
            downloadImage(url: urlImage, completion: { image in
                if let img = image { icon = img }
            })
        } else {
            // load default image
        }
        
        guard let companyName = profileResp["name"] as? String else { return nil }
        guard let currency = profileResp["currency"] as? String else { return nil }
        guard let country = profileResp["country"] as? String else { return nil }
        guard let industry = profileResp["finnhubIndustry"] as? String else { return nil }
        
        let stock = Stock(companyName: companyName, ticker: ticker, quote: quote, currency: currency, country: country, industry: industry, icon: icon)
        
        return stock
    } catch {
        print(error.localizedDescription)
    }
    return nil
}
