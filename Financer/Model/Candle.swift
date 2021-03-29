//
//  Candle.swift
//  Financer
//
//  Created by Никита Раташнюк on 27.03.2021.
//

import Foundation

struct Candle {
    let stock: Stock
    let openPrices: [Double]
    let closePrices: [Double]
    let highPrices: [Double]
    let lowPrices: [Double]
    let timestamps: [Int]
    
    func getFormattedDates() -> [String] {
        var res = [String]()
        for i in 0..<timestamps.count {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            res.append(dateFormatter.string(from: date))
        }
        return res
    }
}

func loadCandle(for stock: Stock, resolution: String) -> Candle? {
    var fromDate: Int
    var resol = resolution
    let toDate = Int(Date().timeIntervalSince1970)
    
    switch resolution {
    case "30m":
        resol = String(30)
        fromDate = Int(Date(timeIntervalSinceNow: -86400 * 1.5).timeIntervalSince1970)
    case "1h":
        resol = String(60)
        fromDate = Int(Date(timeIntervalSinceNow: -86400 * 3).timeIntervalSince1970)
    case "D":
        fromDate = Int(Date(timeIntervalSinceNow: -86400 * 90).timeIntervalSince1970)
    case "W":
        fromDate = Int(Date(timeIntervalSinceNow: -604800 * 50).timeIntervalSince1970)
    case "M":
        fromDate = Int(Date(timeIntervalSinceNow: -2629743 * 50).timeIntervalSince1970)
    case "All":
        resol = "M"
        fromDate = 0
    default:
        resol = "M"
        fromDate = 0
    }
    
    let url = "https://finnhub.io/api/v1/stock/candle?symbol=\(stock.ticker)&resolution=\(resol)&from=\(fromDate)&to=\(toDate)&token=\(FINNHUB_APIKEY)"
    
    print(url)
    
    guard let urlCandle = URL(string: url) else {
        print("API Not Found (candle)")
        return nil
    }
    
    do {
        let content = try String(contentsOf: urlCandle)
        let data = content.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let candleResp = json as? [String: Any] else {
            print("Couldn't parse quote")
            return nil
        }
        
        guard candleResp["s"] as! String == "ok" else {
            print("Could not get information from API")
            return nil
        }
        
        guard let openPrices = candleResp["o"] as? [Double] else { return nil }
        guard let closePrices = candleResp["c"] as? [Double] else { return nil }
        guard let highPrices = candleResp["h"] as? [Double] else { return nil }
        guard let lowPrices = candleResp["l"] as? [Double] else { return nil }
        guard let timestamps = candleResp["t"] as? [Int] else { return nil }
        
        if resolution == "All" && (timestamps.count >= 48) {
            var closePrices1 = [Double]()
            var timestamps1 = [Int]()
            for i in 0..<timestamps.count {
                if i % 12 == 0 {
                    closePrices1.append(closePrices[i])
                    timestamps1.append(timestamps[i])
                }
            }
            
            let candle = Candle(stock: stock, openPrices: openPrices, closePrices: closePrices1, highPrices: highPrices, lowPrices: lowPrices, timestamps: timestamps1)
            
            return candle
        }
        
        let candle = Candle(stock: stock, openPrices: openPrices, closePrices: closePrices, highPrices: highPrices, lowPrices: lowPrices, timestamps: timestamps)
        
        return candle
    } catch {
        print(error.localizedDescription)
    }
    
    return nil
}
