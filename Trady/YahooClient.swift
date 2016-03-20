//
//  YahooClient.swift
//  Trady
//
//  Created by Floris Chabert on 2/29/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Foundation

class YahooClient {
    class DataPoint: NSObject, NSCoding {
        var date: String
        var volume: Double
        var close: Double
        
        init(date: String, close: Double, volume: Double) {
            self.date = date
            self.close = close
            self.volume = volume
        }
        required convenience init(coder decoder: NSCoder) {
            let date = decoder.decodeObjectForKey("date") as! String
            let close = decoder.decodeObjectForKey("close") as! Double
            let volume = decoder.decodeObjectForKey("volume") as! Double
            self.init(date: date, close: close, volume: volume)
        }
        func encodeWithCoder(coder: NSCoder) {
            coder.encodeObject(date, forKey: "date")
            coder.encodeObject(close, forKey: "close")
            coder.encodeObject(volume, forKey: "volume")
        }
    }

    static var historicalData = [String:[DataPoint]]()

    class Quote: NSObject, NSCoding {
        var descr: String = ""
        var price: Double = 0
        var change: Double?
        var pe: Double?
        var cap: String?

        required convenience init(coder decoder: NSCoder) {
            self.init()
            self.descr = decoder.decodeObjectForKey("descr") as! String
        }
        func encodeWithCoder(coder: NSCoder) {
            coder.encodeObject(descr, forKey: "descr")
        }
    }

    static var quotes = [String: Quote]()

    static func loadFromDefaults() {
        if quotes.count == 0 {
            if let data = NSUserDefaults.standardUserDefaults().objectForKey("quotes") as? NSData {
                quotes = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String: Quote]
            }
        }

        if historicalData.count == 0 {
            if let data = NSUserDefaults.standardUserDefaults().objectForKey("historicalData") as? NSData {
                historicalData = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String:[DataPoint]]
            }
        }
    }

    static func updateAccount(account: Account, completion: () -> Void = {}) {

        let stocksToUpdate = account.positions.filter { $0.category == .Equity || $0.category == .Fund }.map{$0.symbol}
        let stocks = stocksToUpdate.map{"\"\($0)\""}.joinWithSeparator(",")

        let baseURL = "https://query.yahooapis.com/v1/public/yql?q="
        let query = "select Symbol,Name,Change,MarketCapitalization,LastTradePriceOnly,PERatio from yahoo.finance.quotes where symbol in (\(stocks))"
        let postfix = "&env=store://datatables.org/alltableswithkeys&format=json&callback="
        let urlString = (baseURL + query + postfix).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

        let urlRequest = NSURLRequest(URL: NSURL(string: urlString!)!)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) {
            data, response, error in

            guard error == nil && data != nil else {
                completion()
                return
            }

            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {
                completion()
                return

            }

            do {
                if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as? NSDictionary {

                    if let quotesData = json.valueForKeyPath("query.results.quote") as? NSArray {

                        for quoteData in quotesData {

                            if let symbol = quoteData["Symbol"] as? String,
                                priceString = quoteData["LastTradePriceOnly"] as? String,
                                price = Double(priceString) {

                                    let quote = Quote()
                                    quote.price = price
                                    quote.change = Double((quoteData["Change"] as? String) ?? "")
                                    quote.descr = (quoteData["Name"] as? String) ?? "-"
                                    quote.cap = quoteData["MarketCapitalization"] as? String
                                    quote.pe = Double((quoteData["PERatio"] as? String) ?? "-")

                                    self.quotes[symbol] = quote
                            }
                        }
                    }
                }
            }
            catch {}

            var change: Double = 0
            var value: Double = 0
            for position in account.positions {
                change += (self.quotes[position.symbol]?.change ?? 0) * position.quantity
                value += (position.price ?? 0) * position.quantity
            }
            account.change = change
            account.value = value + account.cash

            let defaults = NSUserDefaults.standardUserDefaults()
            let data = NSKeyedArchiver.archivedDataWithRootObject(self.quotes) as NSData
            defaults.setObject(data, forKey: "quotes")
            defaults.synchronize()

            completion()
        }
        task.resume()
    }

    static func historical(account:Account, completion: () -> Void = {}) {

        let howManyDays: NSTimeInterval = 100

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var stocksToUpdate = ["^GSPC"]

        stocksToUpdate += account.positions.filter { $0.category == .Equity || $0.category == .Fund }.map{$0.symbol}

        let stocks = stocksToUpdate.map{"\"\($0)\""}.joinWithSeparator(",")
        let startDate = dateFormatter.stringFromDate(NSDate().dateByAddingTimeInterval(-howManyDays*24*60*60))
        let endDate = dateFormatter.stringFromDate(NSDate())

        let baseURL = "https://query.yahooapis.com/v1/public/yql?q="
        let query = "select * from yahoo.finance.historicaldata where symbol in (\(stocks)) and startDate = \"\(startDate)\" and endDate = \"\(endDate)\""

        let postfix = "&env=store://datatables.org/alltableswithkeys&format=json&callback="
        let urlString = (baseURL + query + postfix).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

        let urlRequest = NSURLRequest(URL: NSURL(string: urlString!)!)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) {
            data, response, error in

            guard error == nil && data != nil else {
                completion()
                return
            }

            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {
                completion()
                return
            }

            do {
                if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as? NSDictionary {
                    if let quotes = json.valueForKeyPath("query.results.quote") as? NSArray {
                        historicalData.removeAll()

                        for quote in quotes {
                            if let symbol = quote["Symbol"] as? String,
                                date = quote["Date"] as? String,
                                closeString = quote["Close"] as? String,
                                close = Double(closeString),
                                volumeString = quote["Volume"] as? String,
                                volume = Double(volumeString) {

                                let symbol = symbol.stringByRemovingPercentEncoding!
                                let niceDateFormatter = NSDateFormatter()
                                niceDateFormatter.dateFormat = "MMM d"
                                let dateString = niceDateFormatter.stringFromDate(dateFormatter.dateFromString(date)!)
                                let dataPoint = DataPoint(date: dateString, close: close, volume: volume)

                                if let _ = historicalData[symbol] {
                                    historicalData[symbol]!.insert(dataPoint, atIndex: 0)
                                }
                                else {
                                    historicalData[symbol] = [dataPoint]
                                }
                            }
                        }

                        var portfolioData = [DataPoint]()
                        for i in 0..<historicalData["^GSPC"]!.count {
                            var value: Double = 0
                            let date = historicalData["^GSPC"]!.first!.date

                            for (key, var data) in historicalData {
                                var units: Double = 0
                                for position in account.positions {
                                    if position.symbol == key {
                                        units = position.quantity
                                        break
                                    }
                                }

                                value += units * data[i].close
                            }

                            portfolioData.append(DataPoint(date: date, close: value, volume:historicalData["^GSPC"]![i].volume))
                        }

                        historicalData["Portfolio"] = portfolioData

                        for (_, var data) in historicalData {
                            for i in 1..<data.count {
                                data[i].close /= data[0].close
                                data[i].close -= 1
                            }
                            data[0].close = 0
                        }
                    }
                }
            }
            catch {}

            let defaults = NSUserDefaults.standardUserDefaults()
            let data = NSKeyedArchiver.archivedDataWithRootObject(historicalData) as NSData
            defaults.setObject(data, forKey: "historicalData")
            defaults.synchronize()

            completion()
        }
        task.resume()
    }

}