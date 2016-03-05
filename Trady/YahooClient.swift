//
//  YahooClient.swift
//  Trady
//
//  Created by Floris Chabert on 2/29/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Foundation

class YahooClient {
    class DataPoint: NSObject, NSCoding{
        var date: String
        var close: Double
        init(date: String, close: Double) {
            self.date = date
            self.close = close
        }
        required convenience init(coder decoder: NSCoder) {
            let date = decoder.decodeObjectForKey("date") as! String
            let close = decoder.decodeObjectForKey("close") as! Double
            self.init(date: date, close: close)
        }
        func encodeWithCoder(coder: NSCoder) {
            coder.encodeObject(date, forKey: "date")
            coder.encodeObject(close, forKey: "close")
        }
    }

    static var historicalData = [String:[DataPoint]]()

    static let yahooUrl = "https://download.finance.yahoo.com/d/quotes.csv"

    static func updateAccount(account: Account, completion: () -> Void = {}) {

        var count = 0
        account.sync {
            count = account.positions.count
        }
        if count == 0 {
            return
        }

        var urlString = yahooUrl

        urlString += "?s="

        var positions: [Position]?
        account.sync {
            positions = account.positions
        }

        for position in positions! {
            if [Category.Equity, Category.Fund].contains(position.category) {
                urlString += "\(position.symbol),"
            }
        }
        urlString = urlString[urlString.startIndex..<urlString.endIndex.advancedBy(-1)]

        urlString += "&f=sl1c1n" // SYMBOL,PRICE,CHANGE,DESCR

        let urlRequest = NSURLRequest(URL: NSURL(string: urlString)!)
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

            if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String {
                responseString.enumerateLines() { line, stop in
                    let line = line.stringByReplacingOccurrencesOfString("\"", withString: "")
                    let items = line.characters.split(",").map{String($0)}

                    account.sync() {
                        for position in account.positions {
                            if [Category.Equity, Category.Fund].contains(position.category) {
                                if items[0] == position.symbol {
                                    position.price = Double(items[1]) ?? position.price
                                    position.change = Double(items[2])
                                    position.descr = items[3..<items.count].joinWithSeparator(",") ?? "-"
                                }
                            }
                        }
                        account.positions.sortInPlace { Double($0.quantity)*$0.price > Double($1.quantity)*$1.price }
                    }
                }
            }

            var change: Double = 0
            var value: Double = 0
            account.sync() {
                for position in account.positions {
                    change += (position.change ?? 0) * position.quantity
                    value += (position.price ?? 0) * position.quantity
                }
                account.change = change
                account.value = value
            }

            completion()
        }
        task.resume()
    }

    static func historical(account:Account, completion: () -> Void = {}) {
        if historicalData.count == 0 {
            if let data = NSUserDefaults.standardUserDefaults().objectForKey("historicalData") as? NSData {
                historicalData = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String:[DataPoint]]
            }
        }

        let howManyDays: NSTimeInterval = 100

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var stocksToUpdate = ["^DJI", "^IXIC", "^GSPC"]

        var positions: [Position]?
        account.sync {
            positions = account.positions
        }
        stocksToUpdate += positions!.filter { $0.category == Category.Equity || $0.category == Category.Fund }.map{$0.symbol}

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
                            close = quote["Close"] as? String,
                            value = Double(close) {
                                let symbol = symbol.stringByRemovingPercentEncoding!
                                let niceDateFormatter = NSDateFormatter()
                                niceDateFormatter.dateFormat = "MMM d"
                                let dateString = niceDateFormatter.stringFromDate(dateFormatter.dateFromString(date)!)
                                let dataPoint = DataPoint(date: dateString, close: value)

                                if let _ = historicalData[symbol] {
                                    historicalData[symbol]!.insert(dataPoint, atIndex: 0)
                                }
                                else {
                                    historicalData[symbol] = [dataPoint]
                                }
                            }
                        }

                        var portfolioData = [DataPoint]()
                        for i in 0..<historicalData["^IXIC"]!.count {
                            var value: Double = 0
                            let date = historicalData["^IXIC"]!.first!.date

                            for (key, var data) in historicalData {
                                var units: Double = 0
                                for position in positions! {
                                    if position.symbol == key {
                                        units = position.quantity
                                        break
                                    }
                                }

                                value += units * data[i].close
                            }

                            portfolioData.append(DataPoint(date: date, close: value))
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