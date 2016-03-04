//
//  YahooClient.swift
//  Trady
//
//  Created by Floris Chabert on 2/29/16.
//  Copyright © 2016 Floris Chabert. All rights reserved.
//

import Foundation

class YahooClient {
    static let yahooUrl = "https://download.finance.yahoo.com/d/quotes.csv"

    static func updateAccount(account: Account, completion: () -> Void = {}) {

        if account.positions.count == 0 {
            return
        }

        var urlString = yahooUrl

        urlString += "?s="
        for position in account.positions {
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
            for position in account.positions {
                change += (position.change ?? 0) * position.quantity
                value += (position.price ?? 0) * position.quantity
            }
            account.sync() {
                account.change = change
                account.value = value
            }

            completion()
        }
        task.resume()
    }

    static func historical(account:Account, completion: () -> Void = {}) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let stocksToUpdate = account.positions.filter { $0.category == Category.Equity || $0.category == Category.Fund }
        let stocks = stocksToUpdate.map{"\"\($0.symbol)\""}.joinWithSeparator(",")
        let startDate = dateFormatter.stringFromDate(NSDate().dateByAddingTimeInterval(-30*24*60*60))
        let endDate = dateFormatter.stringFromDate(NSDate())
        let baseURL = "https://query.yahooapis.com/v1/public/yql?q="
        let query = "select * from yahoo.finance.historicaldata where symbol in (\(stocks)) and startDate = \"\(startDate)\" and endDate = \"\(endDate)\""
        print(query)
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

            if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String {
                print(responseString)
            }
            completion()
        }
        task.resume()
    }

}